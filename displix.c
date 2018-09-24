#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>

/**
 * Prints all the display modes for the given display.
 *
 * - note: To print any duplicate, low resolution display modes, pass `true`.
 */
void dspx_PrintDisplayModes( CGDirectDisplayID , bool );

/**
 * Returns the number of online displays.
 */
uint dspx_GetDisplayCount( CGError *_Nullable );

/**
 * Fetches the IDs for all online displays.
 *
 *  - note: The caller is responsible for releasing the array.
 *  - returns: An array with all the IDs for online displays. 
 */
CGDirectDisplayID* dspx_CopyDisplayIDs( uint *_Nullable , CGError *_Nullable );

/**
 * Returns the display mode at the given index.
 */
CGDisplayModeRef _Nullable
dspx_GetDisplayModeAtIndex( CGDirectDisplayID, bool, int );

/**
 * Configures the display with the given mode.
 *
 *  - note: The screen fades during the transition to the new mode.
 */
void dspx_ConfigureDisplayWithMode( CGDirectDisplayID , CGDisplayModeRef , CGError *_Nullable );

/**
 * A struct used for tracking how the program should behave based on input 
 * passed in at runtime.
 */
struct displix_settings {
    CGDirectDisplayID   ID;         // The selected display ID (the system value; not an index).
    int                 modeIndex;  // An index matching a valid display mode available on the display.
    bool                lowRes;     // Determines if duplicated, low resolution modes should be included.
};


//------------------------------------------------------------------------------
// Main - Displix
//------------------------------------------------------------------------------
int main(int argc, char *const argv[]) {
    CGError err; uint displayCount;

    // Get all the displays right away.
    //--------------------------------------------------------------------------
    CGDirectDisplayID *displayIDs = dspx_CopyDisplayIDs(&displayCount, &err);
    printf("Display count: %i\n", displayCount);

    if (err) {
        exit(err);
    }

    // Parse options to see if we're configuring a display. If we're not, the
    // program will simply print out the modes for each display.
    //--------------------------------------------------------------------------
    struct displix_settings options = { 
        CGMainDisplayID(), -1
    };

    int opt;
    while((opt = getopt(argc, argv, "d:m:a")) != -1) {
        switch(opt) {
            case 'a':
                options.lowRes = true;
                break;
            case 'd': 
               { 
                   int index = atoi(optarg);
                   if (index > 0 && index < displayCount) {
                       options.ID = displayIDs[index];
                   } 
               }
               break;
            case 'm': 
               {
                   options.modeIndex = atoi(optarg);
                   break;
               }
        }
    }

    // Set display mode.
    //--------------------------------------------------------------------------
    if (options.modeIndex >= 0) {
        CGDisplayModeRef displayMode = dspx_GetDisplayModeAtIndex(options.ID, options.lowRes, options.modeIndex);

        if (displayMode == NULL) {
            printf("--\t--\t--\n");
            fprintf(stderr, "'%d' is not a valid display mode index.\n", options.modeIndex);
            goto PrintDisplayModes;
        }

        size_t width, height; 
        width  = CGDisplayModeGetWidth(displayMode);
        height = CGDisplayModeGetHeight(displayMode);

        printf("\t[%i] \t%zu\t%zu\n", options.modeIndex, width, height);

        dspx_ConfigureDisplayWithMode(options.ID, displayMode, &err);
        if (err) {
            fprintf(stderr, "Failed to set display mode: %d\n", err);
        }

        goto FreeMemoryAndExit;
    }

PrintDisplayModes:
    for(int i = 0; i < displayCount; i++) {
        printf("--\t--\t--\n");

        printf("DISPLAY: %i\n", i);
        CGDirectDisplayID displayID = displayIDs[i];
        dspx_PrintDisplayModes(displayID, options.lowRes);
    }

FreeMemoryAndExit:
    free(displayIDs);
    return 0;
}

//------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------
CFDictionaryRef _Nullable 
dspx_CreateOptionsDictionary(bool showDupeLowResModes) {
    if (!showDupeLowResModes) {
        return NULL;
    }

    const struct __CFString  *  keys[] = { kCGDisplayShowDuplicateLowResolutionModes };
    const struct __CFBoolean *values[] = { kCFBooleanTrue };
    return CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, NULL, NULL);
}

CFArrayRef _Nullable
dspx_CopyDisplayModes(CGDirectDisplayID displayID, bool showDupeLowResModes) {
    CFDictionaryRef  options = dspx_CreateOptionsDictionary(showDupeLowResModes);
    CFArrayRef  displayModes = CGDisplayCopyAllDisplayModes(displayID, options);
    if (options) {
        CFRelease(options);
    }

    return displayModes;
}

CGDisplayModeRef _Nullable
dspx_GetDisplayModeAtIndex(CGDirectDisplayID displayID, bool showDupeLowResModes, int index) {
    CFArrayRef  displayModes = dspx_CopyDisplayModes(displayID, showDupeLowResModes);
    CFIndex displayModeCount = CFArrayGetCount(displayModes);
    if (index >= displayModeCount) {
        return NULL;
    }

    CGDisplayModeRef displayMode = (CGDisplayModeRef)CFArrayGetValueAtIndex(displayModes, index);
    CFRelease(displayModes);

    return displayMode;
}

void dspx_PrintDisplayModes(CGDirectDisplayID displayID, bool showDupeLowResModes) {
    CFArrayRef  displayModes = dspx_CopyDisplayModes(displayID, showDupeLowResModes);
    CFIndex displayModeCount = CFArrayGetCount(displayModes);

    printf("\tID:\t%i\n", displayID);
    printf("\tModes:\t%li\n", displayModeCount);
    printf("\t-----\t-----\t------\n");
    printf("\tIndex\tWidth\tHeight\n");
    printf("\t-----\t-----\t------\n");

    for (int m = 0; m < displayModeCount; m++) {
        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(displayModes, m);

        size_t width, height; 
        width  = CGDisplayModeGetWidth(mode);
        height = CGDisplayModeGetHeight(mode);

        printf("\t[%i] \t%zu\t%zu\n", m, width, height);
    }

    CFRelease(displayModes);
}

CGDirectDisplayID* dspx_CopyDisplayIDs(uint *displayCount, CGError *_Nullable error) {
    uint count = dspx_GetDisplayCount(NULL);
    if (displayCount != NULL) {
        *displayCount = count;
    }

    CGDirectDisplayID *displays = calloc(count, sizeof(CGDirectDisplayID));
    CGError err = CGGetOnlineDisplayList(UINT32_MAX, displays, NULL);

    if (error != NULL) {
        *error = err;
    }

    return displays;
}

void dspx_ConfigureDisplayWithMode(CGDirectDisplayID displayID, CGDisplayModeRef displayMode, CGError *_Nullable error) {
    CGError err;
    CGDisplayConfigRef config;

    err = CGBeginDisplayConfiguration(&config);
    if (err) {
        if (error != NULL) {
            *error = err;
            return;
        }
    }

    err = CGConfigureDisplayWithDisplayMode(config, displayID, displayMode, NULL);
    if (err) {
        if (error != NULL) {
            *error = err;
            return;
        }
    }

    err = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    if (err) {
        if (error != NULL) {
            *error = err;
            return;
        }
    }
}

uint dspx_GetDisplayCount(CGError *error) {
    CGError err;
    uint displayCount;
    
    err = CGGetOnlineDisplayList(UINT32_MAX, NULL, &displayCount);

    if (error != NULL) {
        *error = err;
    }

    return displayCount;
}
