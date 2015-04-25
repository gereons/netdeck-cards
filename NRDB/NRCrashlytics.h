//
//  NRCrashlytics.h
//  NRDB
//
//  Created by Gereon Steffens on 23.04.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#ifndef NR_CRASHLYTICS_H
#define NR_CRASHLYTICS_H

#if !DEBUG

#import <Crashlytics/Crashlytics.h>

#define CRASH_OBJ_VALUE(value, key) [Crashlytics setObjectValue:value forKey:key]
#define CRASH_INT_VALUE(value, key) [Crashlytics setIntValue:value forKey:key];
#define CRASHLYTICS_DELEGATE    , CrashlyticsDelegate

#else

#define CRASH_OBJ_VALUE(value, key) /* nop */
#define CRASH_INT_VALUE(value, key) /* nop */
#define CRASHLYTICS_DELEGATE        /* nop */

#endif // DEBUG
#endif // NR_CRASHLYTICS_H
