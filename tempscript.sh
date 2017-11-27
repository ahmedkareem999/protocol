#!/bin/bash

gem install gist
find out -name "*.t.sol.json" | xargs -I _ gist _
