#pragma once

#define DecHandler(name) \
    void name##Entry();  \
    void name();

DecHandler(TimerHandler);
DecHandler(SysCallHandler);
DecHandler(PageFaultHandler);
DecHandler(SegmentFaultHandler);