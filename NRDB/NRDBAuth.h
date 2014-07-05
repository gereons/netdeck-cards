//
//  NRDBAuth.h
//  NRDB
//
//  Created by Gereon Steffens on 05.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#ifndef NRDB_NRDBAuth_h
#define NRDB_NRDBAuth_h

// NB: these are C strings!
#define CLIENT_HOST     "netdeck://oauth2"
#define CLIENT_ID       "4_1onrqq7q82w0ow4scww84sw4k004g8cososcg8gog004s4gs08"
#define CLIENT_SECRET   "2myhr1ijml6o4kc0wgsww040o8cc84oso80o0w0s44k4k0c84"
#define PROVIDER_HOST   "http://netrunnerdb.com"

#define CODE_URL        PROVIDER_HOST "/oauth/v2/auth?client_id=" CLIENT_ID "&response_type=code&redirect_uri=" CLIENT_HOST

#define AUTH_URL        PROVIDER_HOST "/oauth/v2/token" 

#endif
