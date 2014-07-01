BEGIN {
    print "<html><head>\
<meta http-equiv='content-type' content='text/html; charset=UTF-8'> \
<style type='text/css'> \
  pre { font-family: 'HelveticaNeue-Light'; white-space: pre-wrap; } \
  h1 { font-size: 110%} \
  h2 { font-size: 100% } \
  h1,h2 { margin: 0; padding: 0} \
</style> \
</head><body><pre>";
}

END {
    print "</pre></body></html>";
}

/## / { $1=""; print "<h2>" substr($0,2) "</h2>"; next; }
/# / { $1=""; print "<h1>" substr($0,2) "</h1>"; next; }
{ print; }

