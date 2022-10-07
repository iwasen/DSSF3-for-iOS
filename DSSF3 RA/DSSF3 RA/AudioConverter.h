//
//  AudioConverter.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2019/08/19.
//  Copyright © 2019 TRC. All rights reserved.
//

#ifndef AudioConverter_h
#define AudioConverter_h

bool AudioConverter(NSURL *inputURL, int *sampleRate, int *channels, NSData **data);

#endif /* AudioConverter_h */
