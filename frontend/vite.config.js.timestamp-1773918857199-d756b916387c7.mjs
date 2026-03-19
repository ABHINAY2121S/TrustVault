// vite.config.js
import { defineConfig } from "file:///E:/trustVault/frontend/node_modules/vite/dist/node/index.js";
import react from "file:///E:/trustVault/frontend/node_modules/@vitejs/plugin-react/dist/index.js";
import tailwindcss from "file:///E:/trustVault/frontend/node_modules/tailwindcss/lib/index.js";
import autoprefixer from "file:///E:/trustVault/frontend/node_modules/autoprefixer/lib/autoprefixer.js";
var vite_config_default = defineConfig({
  plugins: [react()],
  css: {
    postcss: {
      plugins: [
        tailwindcss({
          content: [
            "./index.html",
            "./src/**/*.{js,ts,jsx,tsx}"
          ],
          theme: {
            extend: {
              colors: {
                navy: {
                  950: "#0a0f1e",
                  900: "#0f172a",
                  800: "#1e293b",
                  700: "#334155"
                }
              },
              fontFamily: {
                inter: ["Inter", "sans-serif"]
              }
            }
          },
          plugins: []
        }),
        autoprefixer()
      ]
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcuanMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCJFOlxcXFx0cnVzdFZhdWx0XFxcXGZyb250ZW5kXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCJFOlxcXFx0cnVzdFZhdWx0XFxcXGZyb250ZW5kXFxcXHZpdGUuY29uZmlnLmpzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9FOi90cnVzdFZhdWx0L2Zyb250ZW5kL3ZpdGUuY29uZmlnLmpzXCI7aW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSAndml0ZSdcbmltcG9ydCByZWFjdCBmcm9tICdAdml0ZWpzL3BsdWdpbi1yZWFjdCdcbmltcG9ydCB0YWlsd2luZGNzcyBmcm9tICd0YWlsd2luZGNzcydcbmltcG9ydCBhdXRvcHJlZml4ZXIgZnJvbSAnYXV0b3ByZWZpeGVyJ1xuXG4vLyBodHRwczovL3ZpdGVqcy5kZXYvY29uZmlnL1xuZXhwb3J0IGRlZmF1bHQgZGVmaW5lQ29uZmlnKHtcbiAgcGx1Z2luczogW3JlYWN0KCldLFxuICBjc3M6IHtcbiAgICBwb3N0Y3NzOiB7XG4gICAgICBwbHVnaW5zOiBbXG4gICAgICAgIHRhaWx3aW5kY3NzKHtcbiAgICAgICAgICBjb250ZW50OiBbXG4gICAgICAgICAgICBcIi4vaW5kZXguaHRtbFwiLFxuICAgICAgICAgICAgXCIuL3NyYy8qKi8qLntqcyx0cyxqc3gsdHN4fVwiLFxuICAgICAgICAgIF0sXG4gICAgICAgICAgdGhlbWU6IHtcbiAgICAgICAgICAgIGV4dGVuZDoge1xuICAgICAgICAgICAgICBjb2xvcnM6IHtcbiAgICAgICAgICAgICAgICBuYXZ5OiB7XG4gICAgICAgICAgICAgICAgICA5NTA6ICcjMGEwZjFlJyxcbiAgICAgICAgICAgICAgICAgIDkwMDogJyMwZjE3MmEnLFxuICAgICAgICAgICAgICAgICAgODAwOiAnIzFlMjkzYicsXG4gICAgICAgICAgICAgICAgICA3MDA6ICcjMzM0MTU1JyxcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgIGZvbnRGYW1pbHk6IHtcbiAgICAgICAgICAgICAgICBpbnRlcjogWydJbnRlcicsICdzYW5zLXNlcmlmJ10sXG4gICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICB9LFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcGx1Z2luczogW10sXG4gICAgICAgIH0pLFxuICAgICAgICBhdXRvcHJlZml4ZXIoKSxcbiAgICAgIF0sXG4gICAgfSxcbiAgfSxcbn0pXG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQTBQLFNBQVMsb0JBQW9CO0FBQ3ZSLE9BQU8sV0FBVztBQUNsQixPQUFPLGlCQUFpQjtBQUN4QixPQUFPLGtCQUFrQjtBQUd6QixJQUFPLHNCQUFRLGFBQWE7QUFBQSxFQUMxQixTQUFTLENBQUMsTUFBTSxDQUFDO0FBQUEsRUFDakIsS0FBSztBQUFBLElBQ0gsU0FBUztBQUFBLE1BQ1AsU0FBUztBQUFBLFFBQ1AsWUFBWTtBQUFBLFVBQ1YsU0FBUztBQUFBLFlBQ1A7QUFBQSxZQUNBO0FBQUEsVUFDRjtBQUFBLFVBQ0EsT0FBTztBQUFBLFlBQ0wsUUFBUTtBQUFBLGNBQ04sUUFBUTtBQUFBLGdCQUNOLE1BQU07QUFBQSxrQkFDSixLQUFLO0FBQUEsa0JBQ0wsS0FBSztBQUFBLGtCQUNMLEtBQUs7QUFBQSxrQkFDTCxLQUFLO0FBQUEsZ0JBQ1A7QUFBQSxjQUNGO0FBQUEsY0FDQSxZQUFZO0FBQUEsZ0JBQ1YsT0FBTyxDQUFDLFNBQVMsWUFBWTtBQUFBLGNBQy9CO0FBQUEsWUFDRjtBQUFBLFVBQ0Y7QUFBQSxVQUNBLFNBQVMsQ0FBQztBQUFBLFFBQ1osQ0FBQztBQUFBLFFBQ0QsYUFBYTtBQUFBLE1BQ2Y7QUFBQSxJQUNGO0FBQUEsRUFDRjtBQUNGLENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
