//
// Created by lingo on 19-5-11.
//

#include <iostream>
#include <vector>
#include "db_handle.h"


Driver::Driver() {
    options_.create_if_missing = true;
}

Driver::~Driver() {

}

void Driver::ParseCommandLine() {

    std::string commandstr; // get a line from console/shell

    std::string key;    // parameter key to be passed

    std::string value;  // parameter value to be passed

    std::string paradir; // parameter to be passed to OpenDB

    std::string start;  // parameter to be passed to Scan
    std::string limit;  // parameter to be passed to Scan

    std::vector<std::string> paras; // split commandstr and we get parameters

    leveldb::Slice tmp;

    int execstr = 0; // store which command to execute

    bool error = false;
    bool quit = false;

    bool DBopened = false;

    while (true) {

        bool parabool = false;  // sync or checksum
        bool invalid = false;

        std::getline(std::cin, commandstr);
        paras.clear();
        split(commandstr, ' ', paras);  // split string with space char

        for (const auto& str : paras) {
            tmp = str;
            if (tmp.starts_with("OpenDB")) {
                execstr = 1;
                DBopened = true;
            } else if (tmp.starts_with("CloseDB")) {
                execstr = 2;
            } else if (tmp.starts_with("DeleteDB")) {
                execstr = 3;
            } else if (tmp.starts_with("Get")) {
                execstr = 4;
            } else if (tmp.starts_with("Put")) {
                execstr = 5;
            } else if (tmp.starts_with("Update")) {
                execstr = 6;
            } else if (tmp.starts_with("Delete")) {
                execstr = 7;
            } else if (tmp.starts_with("Scan")) {
                execstr = 8;
            } else if (tmp.starts_with("ReadSeq")) {
                execstr = 9;
            } else if (tmp.starts_with("ReadReverse")) {
                execstr = 10;
            } else if (tmp.starts_with("Quit")) {
                execstr = 11;
            } else if (tmp.starts_with("--Key=")) {
                key = str.substr(6);
            } else if (tmp.starts_with("--Value=")) {
                value = str.substr(8);
            } else if (tmp.starts_with("--sync=")) {
                parabool = str.substr(7) == "true";
            } else if (tmp.starts_with("--checksum=")) {
                parabool = str.substr(11) == "true";
            } else if (tmp.starts_with("--start=")) {
                start = str.substr(8);
            } else if (tmp.starts_with("--limit=")) {
                limit = str.substr(8);
            } else if (tmp.starts_with("--dbfilename=")) {
                paradir = str.substr(13);
            } else {
                invalid = true;
                std::cout << "Invalid flag" << std::endl;
            }
        }

        if (invalid) continue;
        if (!DBopened) {
            std::cout << "Before any other operation, open DB first" << std::endl;
            continue;
        }

        switch (execstr) {
            case 1:
                error = OpenDB(paradir);
                break;
            case 2:
                CloseDB();
                break;
            case 3:
                DeleteDB();
                break;
            case 4:
                Get(key, parabool);
                break;
            case 5:
                error = Put(key, value, parabool);
                break;
            case 6:
                error = Update(key, value, parabool);
                break;
            case 7:
                error = Delete(key, parabool);
                break;
            case 8:
                error = Scan(start, limit, parabool);
                break;
            case 9:
                error = ReadSeq(parabool);
                break;
            case 10:
                error = ReadReverse(parabool);
                break;
            case 11:
                quit = true;
                break;
            default:
                // unreachable code block
                assert(false);
                break;
        }
        if (error) break;
        if (quit) break;
    }
}

bool Driver::OpenDB(std::string dir) {
    if (!dir.empty()) {
        directory_ = dir;
    }
    status_ = leveldb::DB::Open(options_, directory_, &db_);
    return CheckStatus();
}

void Driver::CloseDB() {
    delete db_;
    db_ = nullptr;
    std::cout << "Closed" << std::endl;
}

void Driver::DeleteDB() {
    CloseDB();
    leveldb::DestroyDB(directory_, options_);
    std::cout << "Deleted" << std::endl;
}

void Driver::Get(std::string key, bool checksum) {
    assert(db_ != nullptr);
    std::string rep;
    read_options_.verify_checksums = checksum;
    status_ = db_->Get(read_options_, key, &rep);
    if (status_.IsNotFound()) {
        std::cout << "Corresponding value not found" << std::endl;
    } else {
        std::cout << "Get corresponding value: " << rep << std::endl;
    }
}

bool Driver::Put(std::string key, std::string value, bool sync) {
    assert(db_ != nullptr);
    write_options_.sync = sync;
    status_ = db_->Put(write_options_, key, value);
    return CheckStatus();
}

bool Driver::Update(std::string key, std::string value, bool sync) {
    assert(db_ != nullptr);
    return Put(key, value, sync);
}

bool Driver::Delete(std::string key, bool sync) {
    assert(db_ != nullptr);
    write_options_.sync = sync;
    status_ = db_->Delete(write_options_, key);
    return CheckStatus();
}

bool Driver::Scan(std::string start, std::string limit, bool checksum) {
    assert(db_ != nullptr);
    ClearBuffer();
    read_options_.verify_checksums = checksum;
    leveldb::Iterator* it = db_->NewIterator(read_options_);
    for (it->Seek(start); it->Valid() && it->key().ToString() < limit; it->Next()) {
        keys_.push_back(it->key().ToString());
        values_.push_back(it->value().ToString());
    }
    status_ = it->status();
    delete it;
    PrintResults();
    return CheckStatus();
}

bool Driver::ReadSeq(bool checksum) {
    assert(db_ != nullptr);
    ClearBuffer();
    read_options_.verify_checksums = checksum;
    leveldb::Iterator* it = db_->NewIterator(read_options_);
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        keys_.push_back(it->key().ToString());
        values_.push_back(it->value().ToString());
    }
    status_ = it->status();
    delete it;
    PrintResults();
    return CheckStatus();
}

bool Driver::ReadReverse(bool checksum) {
    assert(db_ != nullptr);
    ClearBuffer();
    read_options_.verify_checksums = checksum;
    leveldb::Iterator* it = db_->NewIterator(read_options_);
    for (it->SeekToLast(); it->Valid(); it->Prev()) {
        keys_.push_back(it->key().ToString());
        values_.push_back(it->value().ToString());
    }
    status_ = it->status();
    delete it;
    PrintResults();
    return CheckStatus();
}

// return true iff error occurred
bool Driver::CheckStatus() const {
    if (!status_.ok()) {
        std::cout << status_.ToString() << std::endl;
        return true;
    } else {
        std::cout << "Operation Succeeded" << std::endl;
        return false;
    }
}

void Driver::ClearBuffer() {
    keys_.clear();
    values_.clear();
}

void Driver::PrintResults() {
    std::cout << "K: \t";
    for (const auto& key : keys_) {
        std::cout << key << " \t";
    }
    std::cout << std::endl;
    std::cout << "V: \t";
    for (const auto& value : values_) {
        std::cout << value << " \t";
    }
    std::cout << std::endl;
}

