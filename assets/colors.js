/*
 * Convenience js module that defines the site-wide colours
 */

// Define individual HSLA colors as constants
const chiliRed = "hsla(5, 100%, 55%, 1)"; // #e83a21
const pearl = "hsla(39, 40%, 90%, 1)"; // #e3dabe
const black = "hsla(0, 0%, 3%, 1)"; // #070302
const dun = "hsla(39, 20%, 80%, 1)"; // #deb587
const bloodRed = "hsla(0, 100%, 20%, 1)"; // #5b1208

const whiteAlabaster = "hsla(40, 20%, 95%, 1)"; // #f3efe3
const linen = "hsla(40, 30%, 97%, 1)"; // #faf1e6

const aerospaceOrange = "hsla(30, 100%, 50%, 1)"; // #fd4f00
const coralOrange = "hsla(15, 100%, 60%, 1)"; // #ff8349
const atomicTangerine = "hsla(15, 100%, 70%, 1)"; // #ff9b6d

const brown = "hsla(15, 80%, 30%, 1)"; // #922e00
const sienna = "hsla(10, 80%, 25%, 1)"; // #7f2800
const rust = "hsla(0, 85%, 40%, 1)"; // #ae3700

// Define color variables using the constants without the 'color' prefix
const colors = {
  aerospaceOrange: "hsla(30, 100%, 50%, 1)",
  brand: aerospaceOrange,
  brandLight: atomicTangerine,
  brandExtraLight: linen,
  brandAccent: aerospaceOrange,
  brandAccentLight: atomicTangerine,

  brandDark: brown,
  brandExtraDark: sienna,

  primary: chiliRed,
  primaryAccent: chiliRed,
  primaryBackground: whiteAlabaster,
  secondary: bloodRed,
  secondaryBackground: dun,
  text: black,
};

export default colors;
