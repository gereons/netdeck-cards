BEGIN {
    print "<html><head>\n\
<meta http-equiv='content-type' content='text/html; charset=UTF-8'>\n\
<meta name='viewport' content='width=device-width, initial-scale=1.0, user-scalable=no'>\n\
<style type='text/css'>\n\
  pre { font-family: '-apple-system','HelveticaNeue-Light'; font-size: 17px; white-space: pre-wrap; }\n\
  h1 { font-size: 110% }\n\
  h2 { font-size: 100% }\n\
  h1,h2 { margin: 0; padding: 0}\n\
  @media (prefers-color-scheme: dark) {\n\
    * { background-color: #000; color: #fff; }\n\
  }\n\
</style>\n\
</head><body><pre>";
}

END {
    print "</pre></body></html>";
}

/^# / { $1=""; print "<h1>" substr($0,2) "</h1>"; next; }
/^## / { $1=""; print "<h2>" substr($0,2) "</h2>"; next; }
{ print; }

