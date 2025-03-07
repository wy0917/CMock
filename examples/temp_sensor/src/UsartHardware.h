/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#ifndef _USARTHARDWARE_H
#define _USARTHARDWARE_H

#include "Types.h"

void UsartHardware_Init(uint8 baudRateRegisterSetting);
void UsartHardware_TransmitString(char* data);

#endif // _USARTHARDWARE_H
