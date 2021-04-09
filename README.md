# ISC Mining (EDOC17)
This project contains a script implementing the projection and transformation algorithm, presented in the Paper "Discovering Instance-Spanning Constraints from Process Execution Logs based on Classification Techniques" by Karolin Winter and Stefanie Rinderle-Ma (https://ieeexplore.ieee.org/document/8089866).

## Dependencies
```sh
$ gem install xes
$ gem install xml-smart
$ gem install rarff
```

## Run
ruby projection_transformation_algorithm.rb --data data/centrifugation.xes --results results
