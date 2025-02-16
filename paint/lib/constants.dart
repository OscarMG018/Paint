// Defineix les eines/funcions que hi ha disponibles a flutter
const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "A function that draws a circle with a given center and radius @param {number} x @param {number} y @param {number} radius",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"}
        },
        "required": ["x", "y", "radius"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description":
          "A function that draws a line with a given start and end coordinates, with the given color and stroke width, all color values go from 0.0 to 1.0 @param {number} startX @param {number} startY @param {number} endX @param {number} endY @param {number} width @param {object} color{ @param {number} r @param {number} g @param {number} b @Optional @param {number} a}",
      "parameters": {
        "type": "object",
        "properties": {
          "startX": {"type": "number"},
          "startY": {"type": "number"},
          "endX": {"type": "number"},
          "endY": {"type": "number"},
          "width": {"type": "number"},
          "color": {
            "type": "object",
            "properties": {
              "r": { "type": "integer", "minimum": 0, "maximum": 1 },
              "g": { "type": "integer", "minimum": 0, "maximum": 1 },
              "b": { "type": "integer", "minimum": 0, "maximum": 1 },
              "a": { "type": "number", "minimum": 0, "maximum": 1 }
            },
            "required": ["r", "g", "b"]
          }
        },
        "required": ["startX", "startY", "endX", "endY"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description":
          "A function that draws a rectangle with a given top-left and bottom-right coordinates, border and fill colors, and optional gradient. Colors are RGB values (0-1) with optional alpha (0-1). For gradient, specify type ('linear' or 'radial') and an array of colors. Linear gradient goes from top-left to bottom-right, radial gradient starts from center. @param {number} topLeftX @param {number} topLeftY @param {number} bottomRightX @param {number} bottomRightY @param {object} borderColor @param {object} fillColor @param {number} borderWidth @param {object} gradient",
      "parameters": {
        "type": "object",
        "properties": {
          "topLeftX": {"type": "number"},
          "topLeftY": {"type": "number"},
          "bottomRightX": {"type": "number"},
          "bottomRightY": {"type": "number"},
          "borderColor": {
            "type": "object",
            "properties": {
              "r": { "type": "integer", "minimum": 0, "maximum": 1 },
              "g": { "type": "integer", "minimum": 0, "maximum": 1 },
              "b": { "type": "integer", "minimum": 0, "maximum": 1 },
              "a": { "type": "number", "minimum": 0, "maximum": 1 }
            },
            "required": ["r", "g", "b"]
          },
          "fillColor": {
            "type": "object",
            "properties": {
              "r": { "type": "integer", "minimum": 0, "maximum": 1 },
              "g": { "type": "integer", "minimum": 0, "maximum": 1 },
              "b": { "type": "integer", "minimum": 0, "maximum": 1 },
              "a": { "type": "number", "minimum": 0, "maximum": 1 }
            },
            "required": ["r", "g", "b"]
          },
          "borderWidth": {"type": "number"},
          "gradient": {
            "type": "object",
            "properties": {
              "type": {
                "type": "string",
                "enum": ["linear", "radial"]
              },
              "colors": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "r": { "type": "integer", "minimum": 0, "maximum": 1 },
                    "g": { "type": "integer", "minimum": 0, "maximum": 1 },
                    "b": { "type": "integer", "minimum": 0, "maximum": 1 },
                    "a": { "type": "number", "minimum": 0, "maximum": 1 }
                  }
                }
              }
            },
            "required": ["type", "colors"]
          }
        },
        "required": ["topLeftX", "topLeftY", "bottomRightX", "bottomRightY"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "A function that draws a circle with a given center and radius, border and fill colors, and optional gradient. Colors are RGB values (0-1) with optional alpha (0-1). For gradient, specify type ('linear' or 'radial') and an array of colors. Linear gradient goes from top-left to bottom-right, radial gradient starts from center and goes outward. @param {number} x @param {number} y @param {number} radius @param {object} borderColor @param {object} fillColor @param {number} borderWidth @param {object} gradient",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"},
          "borderColor": {
            "type": "object",
            "properties": {
              "r": { "type": "integer", "minimum": 0, "maximum": 1 },
              "g": { "type": "integer", "minimum": 0, "maximum": 1 },
              "b": { "type": "integer", "minimum": 0, "maximum": 1 },
              "a": { "type": "number", "minimum": 0, "maximum": 1 }
            },
            "required": ["r", "g", "b"]
          },
          "fillColor": {
            "type": "object",
            "properties": {
              "r": { "type": "integer", "minimum": 0, "maximum": 1 },
              "g": { "type": "integer", "minimum": 0, "maximum": 1 },
              "b": { "type": "integer", "minimum": 0, "maximum": 1 },
              "a": { "type": "number", "minimum": 0, "maximum": 1 }
            },
            "required": ["r", "g", "b"]
          },
          "borderWidth": {"type": "number"},
          "gradient": {
            "type": "object",
            "properties": {
              "type": {
                "type": "string",
                "enum": ["linear", "radial"]
              },
              "colors": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "r": { "type": "integer", "minimum": 0, "maximum": 1 },
                    "g": { "type": "integer", "minimum": 0, "maximum": 1 },
                    "b": { "type": "integer", "minimum": 0, "maximum": 1 },
                    "a": { "type": "number", "minimum": 0, "maximum": 1 }
                  }
                }
              }
            },
            "required": ["type", "colors"]
          }
        },
        "required": ["x", "y", "radius"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_text",
      "description":
          "A function that draws text with customizable font properties. Colors are RGB values (0-1) with optional alpha (0-1). @param {string} text @param {number} x @param {number} y @param {object} color @param {number} fontSize @param {string} fontFamily @param {string} fontStyle @param {string} fontWeight",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {"type": "string"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "color": {
            "type": "object",
            "properties": {
              "r": { "type": "integer", "minimum": 0, "maximum": 1 },
              "g": { "type": "integer", "minimum": 0, "maximum": 1 },
              "b": { "type": "integer", "minimum": 0, "maximum": 1 },
              "a": { "type": "number", "minimum": 0, "maximum": 1 }
            },
            "required": ["r", "g", "b"]
          },
          "fontSize": {"type": "number"},
          "fontFamily": {
            "type": "string",
            "enum": ["Roboto", "Arial", "Helvetica", "Times New Roman", "Courier"]
          },
          "fontStyle": {
            "type": "string",
            "enum": ["normal", "italic"]
          },
          "fontWeight": {
            "type": "string",
            "enum": ["normal", "bold"]
          }
        },
        "required": ["text", "x", "y"]
      }
    }
  }
];
