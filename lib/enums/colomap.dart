enum ColorMap {
  bluegreenyellowred,
  grey,
  blue,
  yelloworangered,
  rainbow,
  blackredyellow,
  bluewhitered,
  redwhiteblue,
}

Map<ColorMap, Map<double, List<int>>> colorMapData = {
  ColorMap.yelloworangered: {
    0.2: [255, 200, 0],
    0.5: [255, 150, 0],
    0.8: [255, 50, 0],
    1.0: [255, 0, 0],
    0.0: [255, 255, 0],
  },
  ColorMap.bluegreenyellowred: {
    0.2: [0, 255, 0],
    0.5: [0, 255, 255],
    0.8: [0, 0, 255],
    1.0: [255, 0, 0],
    0.0: [255, 255, 0],
  },
  ColorMap.grey: {
    0.2: [200, 200, 200],
    0.5: [150, 150, 150],
    0.8: [100, 100, 100],
    1.0: [50, 50, 50],
    0.0: [255, 255, 255],
  },
};
