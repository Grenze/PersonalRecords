//
// Created by lingo on 19-5-11.
//

#include <iostream>
#include <sstream>
#include <vector>
#include <iterator>
#include "leveldb/db.h"

#ifndef LEVELDBAPP_DB_HANDLE_H
#define LEVELDBAPP_DB_HANDLE_H

template<typename Out>
static void split(const std::string& s, char delim, Out result) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        if (!item.empty()) {
            *(result++) = item;
        }
    }
}

static void split(const std::string& s, char delim, std::vector<std::string>& elems) {
    split(s, delim, std::back_inserter(elems));
}

class Driver {

public:

    Driver();
    ~Driver();

    void ParseCommandLine();

    // default open leveldb in tmp/leveldb
    bool OpenDB(std::string dir);

    void CloseDB();

    void DeleteDB();

    void Get(std::string key, bool checksum = false);

    bool Put(std::string key, std::string value, bool sync = false);

    bool Update(std::string key, std::string value, bool sync = false);

    bool Delete(std::string key, bool sync = false);

    bool Scan(std::string start, std::string limit, bool checksum = false);

    bool ReadSeq(bool checksum = false);

    bool ReadReverse(bool checksum = false);

private:

    leveldb::DB* db_;
    leveldb::Options options_;
    leveldb::ReadOptions read_options_;
    leveldb::WriteOptions write_options_;
    leveldb::Status status_;
    std::string directory_ = "/tmp/leveldb";
    std::vector<std::string> keys_;
    std::vector<std::string> values_;

    bool CheckStatus() const;

    void ClearBuffer();

    void PrintResults();

    Driver(const Driver&);
    void operator=(const Driver&);
};


#endif //LEVELDBAPP_DB_HANDLE_H
