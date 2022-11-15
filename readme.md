brew install openssl@1.1
gem install eventmachine -v '1.2.7' -- --with-openssl-dir=$(brew --prefix openssl@1.1)
