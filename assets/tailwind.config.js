// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/vyasa_web.ex",
    "../lib/vyasa/display/user_mode.ex",
    "../lib/vyasa_web/**/*.*ex",
  ],
  theme: {
    extend: {
      animation: {
        ripple: "ripple 1s cubic-bezier(0.4, 0, 0.2, 1) infinite",
        fade: 'fadeIn 1s ease-in-out',
        pulseBorder: "pulseBorder 1.5s ease-in-out infinite",
      },
      keyframes: {
        fadeIn: {
					from: { opacity: 0 },
					to: { opacity: 1 },
				},
        ripple: {
          "0%": { transform: "scale(0)", opacity: "1" },
          "100%": { transform: "scale(4)", opacity: "0" },
        },
        pulseBorder: {
          "0%": {
            borderColor: "transparent",
            transform: "scale(1)",
          },
          "50%": {
            borderColor: "var(--color-brand)", // Use your defined brand color
            transform: "scale(1.05)", // Slightly scale up
          },
          "100%": {
            borderColor: "transparent",
            transform: "scale(1)",
          },
        },
      },
      fontFamily: {
        dn: ['"Karm"', "sans-serif"],
        ta: ['"Vyas", "sans-serif"'],
      },
      fontSize: {
        xs: "0.65rem",
      },
      fontSize: {
        xs: "0.65rem",
      },
      colors: {
        primary: "var(--color-primary)",
        ink: "#1E1024",
        primaryAccent: "var(--color-primary-accent)",
        secondary: "var(--color-secondary)",
        primaryBackground: "var(--color-primary-background)",
        secondary: "var(--color-secondary)",
        brand: "var(--color-brand)",
        brandLight: "var(--color-brand-light)",
        brandExtraLight: "var(--color-brand-extra-light)",
        brandAccent: "var(--color-brand-accent)",
        brandAccentLight: "var(--color-brand-accent-light)",
        brandDark: "var(--color-brand-dark)",
        brandExtraDark: "var(--color-brand-extra-dark)",
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [
        ".phx-no-feedback&",
        ".phx-no-feedback &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]),
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values },
      );
    }),
    // Embeds Custom SVG Icons (https://heroicons.com) into your app.css bundle
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/customicons");
      let values = {};
      fs.readdirSync(iconsDir).forEach((file) => {
        let name = path.basename(file, ".svg");
        values[name] = { name, fullPath: path.join(iconsDir, file) };
      });
      matchComponents(
        {
          custom: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--custom-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--custom-${name})`,
              mask: `var(--custom-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values },
      );
    }),
  ],
};
