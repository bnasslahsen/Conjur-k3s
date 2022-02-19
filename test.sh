#!/bin/bash



export conjur="docker run --rm -it --add-host host-1:10.0.0.1 -v $(pwd):/root cyberark/conjur-cli:5"
bash -c "yes yes | $conjur init --url https://host-1 --account devops-org"

$conjur policy load root root/policies/app-policy.yml


