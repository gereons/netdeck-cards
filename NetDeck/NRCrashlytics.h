//
//  NRCrashlytics.h
//  Net Deck
//
//  Created by Gereon Steffens on 23.04.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#ifndef NR_CRASHLYTICS_H
#define NR_CRASHLYTICS_H

#define DEBUG_CRASHLYTICS   0
#define USE_CRASHLYTICS     defined(RELEASE) || defined(ADHOC) || DEBUG_CRASHLYTICS

#if USE_CRASHLYTICS

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#define CRASHLYTICS_DELEGATE        , CrashlyticsDelegate
#define LOG_EVENT(name, attrs)      [Answers logCustomEventWithName:name customAttributes:attrs]

#else

#define CRASHLYTICS_DELEGATE        /* nop */
#define LOG_EVENT(name, attrs)      /* nop */

#endif // USE_CRASHLYTICS
#endif // NR_CRASHLYTICS_H
