# check_gbg_air
Uses data.goteborg.se API to feed performance data to OP5 Monitor or Nagios 

```
Usage:
<path> <input-file-name>

    -a  Check via http
        -k  key (required by http)
        -u  url (required by http)
    -d  debug enabled
    -f  Check using stdin
    -h  help
    
Example:
# ./check_gbg_air.pl -a -k "my secret key"

Example from file:
# ./check_gbg_air.pl -f < example_data_1.json
```
