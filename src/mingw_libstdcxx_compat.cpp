// GCC 13's MinGW import library references this link-time marker to keep
// libstdc++ linked. The runtime bundled with our Qt kit does not export it.
// Supply the marker locally, as in SpeechRateMeter2, so we can retain Qt's
// runtime (which also provides __cxa_call_terminate required by Qt6Core).
// This marker performs no stream initialization; that belongs to libstdc++.
#if defined(__MINGW32__) && defined(__GNUC__) && __GNUC__ == 13
namespace std {
void ios_base_library_init() {}
}
#endif
