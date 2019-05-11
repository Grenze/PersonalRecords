

#include "db_handle.h"


int main() {

    std::string test = "update  100 122";
    std::vector<std::string> ans;
    split(test, ' ', ans);
    for (const auto& str : ans) {
        std::cout << str << std::endl;
    }

    Driver* driver_ = new Driver();
    driver_->ParseCommandLine();

    return 0;
}