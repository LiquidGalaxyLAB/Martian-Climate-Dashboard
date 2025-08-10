enum ColorMap {
  bluegreenyellowred,
  grey,
  blue,
  yelloworangered,
  rainbow,
  blackredyellow,
  bluewhitered,
  redwhiteblue,
  redyellowgreenblue,
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
    0.0: [0, 0, 255],
    0.2: [0, 255, 0],
    0.5: [255, 255, 0],
    0.8: [255, 128, 0],
    1.0: [255, 0, 0],
  },
  ColorMap.grey: {
    0.2: [200, 200, 200],
    0.5: [150, 150, 150],
    0.8: [100, 100, 100],
    1.0: [50, 50, 50],
    0.0: [255, 255, 255],
  },
  ColorMap.redyellowgreenblue: {
    0.0: [255, 0, 0], // red
    0.2: [255, 156, 0], // orange
    0.5: [128, 255, 0], // yellow-green
    0.8: [0, 150, 105], // teal
    1.0: [0, 0, 255], // blue
  },
};
