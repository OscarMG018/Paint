import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:paint/constants.dart';
import 'package:paint/Models/drawable.dart';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isInitial = true;
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription;
  final model = 'llama3.2';
  final String sytemPrompt = "You are a painting assistant. You are given a set of tools that can be used to draw on a canvas. " +
  "You can use these tools to draw lines, circles, rectangles, and text. Your task is to use the tools to fullfil the request from the user. "+
  "The canvas coordinates are 0,0 at the top left and 400,400 at the bottom right which means the center is at 200,200. "+
  "Make sure to use the tools correctly, in the tool_calls section and not in your response, and in the right format, a list of "+
  "json objects with name and arguments. e.g. [{function: {\"name\": \"draw_circle\", \"arguments\": {\"x\": 100, \"y\": 200, \"radius\": 50}}}]. "+
  "In all tools colors are RGBA values (0-1) with optional alpha (0-1). "+
  "For shapes that support gradients (circles and rectangles), you can specify a gradient instead of a fill color. "+
  "Gradients require a type ('linear' or 'radial') and an array of colors. For example: "+
  "\"gradient\": {\"type\": \"linear\", \"colors\": [{\"r\": 1, \"g\": 0, \"b\": 0}, {\"r\": 0, \"g\": 0, \"b\": 1}]} "+
  "Linear gradients go from top-left to bottom-right, while radial gradients start from the center and go outward.";

  final List<Drawable> drawables = [];

  String get responseText =>
      _isInitial ? "..." : (_isLoading ? "Esperant ..." : _responseText);

  bool get isLoading => _isLoading;

  AppData() {
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    notifyListeners();
  }

  Future<void> callStream({required String question}) async {
    _isInitial = false;
    setLoading(true);

    try {
      var request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/generate'),
      );

      request.headers.addAll({'Content-Type': 'application/json'});
      request.body =
          jsonEncode({'model': model, 'prompt': question, 'stream': true});

      var streamedResponse = await _client!.send(request);
      _streamSubscription =
          streamedResponse.stream.transform(utf8.decoder).listen((value) {
        var jsonResponse = jsonDecode(value);
        var jsonResponseStr = jsonResponse['response'];
        _responseText = "$_responseText\n$jsonResponseStr";
        print(_responseText);
        notifyListeners();
      }, onError: (error) {
        if (error is http.ClientException &&
            error.message == 'Connection closed while receiving data') {
          _responseText += "\nRequest cancelled.";
        } else {
          _responseText += "\nError during streaming: $error";
        }
        setLoading(false);
        notifyListeners();
      }, onDone: () {
        setLoading(false);
      });
    } catch (e) {
      _responseText = "\nError during streaming.";
      setLoading(false);
      notifyListeners();
    }
  }

  dynamic fixJsonInStrings(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, fixJsonInStrings(value)));
    } else if (data is List) {
      return data.map(fixJsonInStrings).toList();
    } else if (data is String) {
      try {
        // Si és JSON dins d'una cadena, el deserialitzem
        final parsed = jsonDecode(data);
        return fixJsonInStrings(parsed);
      } catch (_) {
        // Si no és JSON, retornem la cadena tal qual
        return data;
      }
    }
    // Retorna qualsevol altre tipus sense canvis (números, booleans, etc.)
    return data;
  }

  dynamic cleanKeys(dynamic value) {
    if (value is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      value.forEach((k, v) {
        result[k.trim()] = cleanKeys(v);
      });
      return result;
    }
    if (value is List) {
      return value.map(cleanKeys).toList();
    }
    return value;
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    _isInitial = false;
    setLoading(true);

    final body = {
      "model": "llama3.2",
      "stream": false,
      "messages": [
        {"role": "system", "content": sytemPrompt},
        {"role": "user", "content": userPrompt}
      ],
      "tools": tools
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Full model response: ${response.body}");
        if (jsonResponse['message'] != null &&
            jsonResponse['message']['tool_calls'] != null) {
          final toolCalls = (jsonResponse['message']['tool_calls'] as List)
              .map((e) => cleanKeys(e))
              .toList();
          for (final tc in toolCalls) {
            if (tc['function'] != null) {
              _processFunctionCall(tc['function']);
            }
            else if (tc['name'] != null && tc['arguments'] != null) {
              _processFunctionCall(tc);
            }
          }
        }
        else if (jsonResponse['message'] != null &&
            jsonResponse['message']['content'] != null) {
          _responseText += "\n${jsonResponse['message']['content']}";
          //try to parse the response as json
          try {
            final parsed = jsonDecode(jsonResponse['message']['content']);
            final toolCalls = (parsed as List)
              .map((e) => cleanKeys(e))
              .toList();
            for (final tc in toolCalls) {
              if (tc['function'] != null) {
                _processFunctionCall(tc['function']);
              }
              else if (tc['name'] != null && tc['arguments'] != null) {
                _processFunctionCall(tc);
              }
            }
          } catch (e) {
            // ignore
          }
        }
        setLoading(false);
      } else {
        setLoading(false);
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      print("Error during API call: $e");
      setLoading(false);
    }
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _responseText += "\nRequest cancelled.";
    setLoading(false);
    notifyListeners();
  }

  double parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _processFunctionCall(Map<String, dynamic> functionCall) {
    final fixedJson = fixJsonInStrings(functionCall);
    final parameters = fixedJson['arguments'];
    print("Parameters: $parameters");
    String name = fixedJson['name'];
    String infoText = "Draw $name: $parameters";

    print(infoText);
    _responseText = "$_responseText\n$infoText";

    switch (name) {
      case 'draw_circle':
        if (parameters['x'] != null &&
            parameters['y'] != null &&
            parameters['radius'] != null) {
          final dx = parseDouble(parameters['x']);
          final dy = parseDouble(parameters['y']);
          final radius = max(0.0, parseDouble(parameters['radius']));
          
          Color borderColor = Colors.black;
          Color fillColor = Colors.transparent;
          double borderWidth = 2.0;
          Gradient? gradient;

          if (parameters['borderColor'] != null) {
            final bc = parameters['borderColor'];
            borderColor = Color.fromARGB(
              (parseDouble(bc['a'] ?? 1) * 255).toInt(),
              (parseDouble(bc['r']) * 255).toInt(),
              (parseDouble(bc['g']) * 255).toInt(),
              (parseDouble(bc['b']) * 255).toInt(),
            );
          }

          if (parameters['fillColor'] != null) {
            final fc = parameters['fillColor'];
            fillColor = Color.fromARGB(
              (parseDouble(fc['a'] ?? 1) * 255).toInt(),
              (parseDouble(fc['r']) * 255).toInt(),
              (parseDouble(fc['g']) * 255).toInt(),
              (parseDouble(fc['b']) * 255).toInt(),
            );
          }

          if (parameters['borderWidth'] != null) {
            borderWidth = parseDouble(parameters['borderWidth']);
          }

          if (parameters['gradient'] != null && parameters['gradient']['colors'] != null) {
            final gradientParams = parameters['gradient'];
            final colors = (gradientParams['colors'] as List).map((c) => 
              Color.fromARGB(
                (parseDouble(c['a'] ?? 1) * 255).toInt(),
                (parseDouble(c['r'] ?? 0) * 255).toInt(),
                (parseDouble(c['g'] ?? 0) * 255).toInt(),
                (parseDouble(c['b'] ?? 0) * 255).toInt(),
              )
            ).toList();

            final gradientType = gradientParams['type'] as String? ?? 'linear';
            
            // Default alignment points
            Alignment begin = Alignment.topLeft;
            Alignment end = Alignment.bottomRight;
            Alignment center = Alignment.center;

            // Parse alignment points if provided
            if (gradientParams['begin'] != null) {
              begin = Alignment(
                parseDouble(gradientParams['begin']['x'] ?? -1),
                parseDouble(gradientParams['begin']['y'] ?? -1)
              );
            }
            if (gradientParams['end'] != null) {
              end = Alignment(
                parseDouble(gradientParams['end']['x'] ?? 1),
                parseDouble(gradientParams['end']['y'] ?? 1)
              );
            }
            if (gradientParams['center'] != null) {
              center = Alignment(
                parseDouble(gradientParams['center']['x'] ?? 0),
                parseDouble(gradientParams['center']['y'] ?? 0)
              );
            }

            switch (gradientType) {
              case 'linear':
                gradient = LinearGradient(
                  colors: colors,
                  begin: begin,
                  end: end,
                );
                break;
              case 'radial':
                gradient = RadialGradient(
                  colors: colors,
                  center: center,
                  radius: 1.0,
                );
                break;
              case 'sweep':
                gradient = SweepGradient(
                  colors: colors,
                  center: center,
                );
                break;
              default:
                gradient = LinearGradient(
                  colors: colors,
                  begin: begin,
                  end: end,
                );
            }
          }

          addDrawable(Circle(
            center: Offset(dx, dy),
            radius: radius,
            borderColor: borderColor,
            fillColor: fillColor,
            borderWidth: borderWidth,
            gradient: gradient,
          ));
        }
        break;

      case 'draw_line':
        if (parameters['startX'] != null &&
            parameters['startY'] != null &&
            parameters['endX'] != null &&
            parameters['endY'] != null) {
          final startX = parseDouble(parameters['startX']);
          final startY = parseDouble(parameters['startY']);
          final endX = parseDouble(parameters['endX']);
          final endY = parseDouble(parameters['endY']);
          final colorR = parseDouble(parameters['color']['r'] ?? 0)*255;
          final colorG = parseDouble(parameters['color']['g'] ?? 0)*255;
          final colorB = parseDouble(parameters['color']['b'] ?? 0)*255;
          final colorA = parseDouble(parameters['color']['a'] ?? 1)*255;
          final width = parseDouble(parameters['width'] ?? 2);
          final color = Color.fromARGB(colorA.toInt(), colorR.toInt(), colorG.toInt(), colorB.toInt());
          final start = Offset(startX, startY);
          final end = Offset(endX, endY);
          addDrawable(Line(start: start, end: end, color: color, strokeWidth: width));
          print(drawables);
        } else {
          print("Missing line properties: $parameters");
        }
        break;

      case 'draw_rectangle':
        if (parameters['topLeftX'] != null &&
            parameters['topLeftY'] != null &&
            parameters['bottomRightX'] != null &&
            parameters['bottomRightY'] != null) {
          final topLeftX = parseDouble(parameters['topLeftX']);
          final topLeftY = parseDouble(parameters['topLeftY']);
          final bottomRightX = parseDouble(parameters['bottomRightX']);
          final bottomRightY = parseDouble(parameters['bottomRightY']);
          
          Color borderColor = Colors.black;
          Color fillColor = Colors.transparent;
          double borderWidth = 2.0;
          Gradient? gradient;

          if (parameters['borderColor'] != null) {
            final bc = parameters['borderColor'];
            borderColor = Color.fromARGB(
              (parseDouble(bc['a'] ?? 1) * 255).toInt(),
              (parseDouble(bc['r'] ?? 0) * 255).toInt(),
              (parseDouble(bc['g'] ?? 0) * 255).toInt(),
              (parseDouble(bc['b'] ?? 0) * 255).toInt(),
            );
          }

          if (parameters['fillColor'] != null) {
            final fc = parameters['fillColor'];
            fillColor = Color.fromARGB(
              (parseDouble(fc['a'] ?? 1) * 255).toInt(),
              (parseDouble(fc['r'] ?? 0) * 255).toInt(),
              (parseDouble(fc['g'] ?? 0) * 255).toInt(),
              (parseDouble(fc['b'] ?? 0) * 255).toInt(),
            );
          }

          if (parameters['borderWidth'] != null) {
            borderWidth = parseDouble(parameters['borderWidth']);
          }

          if (parameters['gradient'] != null && parameters['gradient']['colors'] != null) {
            final gradientParams = parameters['gradient'];
            final colors = (gradientParams['colors'] as List).map((c) => 
              Color.fromARGB(
                (parseDouble(c['a'] ?? 1) * 255).toInt(),
                (parseDouble(c['r'] ?? 0) * 255).toInt(),
                (parseDouble(c['g'] ?? 0) * 255).toInt(),
                (parseDouble(c['b'] ?? 0) * 255).toInt(),
              )
            ).toList();

            final gradientType = gradientParams['type'] as String? ?? 'linear';
            
            // Default alignment points
            Alignment begin = Alignment.topLeft;
            Alignment end = Alignment.bottomRight;
            Alignment center = Alignment.center;

            // Parse alignment points if provided
            if (gradientParams['begin'] != null) {
              begin = Alignment(
                parseDouble(gradientParams['begin']['x'] ?? -1),
                parseDouble(gradientParams['begin']['y'] ?? -1)
              );
            }
            if (gradientParams['end'] != null) {
              end = Alignment(
                parseDouble(gradientParams['end']['x'] ?? 1),
                parseDouble(gradientParams['end']['y'] ?? 1)
              );
            }
            if (gradientParams['center'] != null) {
              center = Alignment(
                parseDouble(gradientParams['center']['x'] ?? 0),
                parseDouble(gradientParams['center']['y'] ?? 0)
              );
            }

            switch (gradientType) {
              case 'linear':
                gradient = LinearGradient(
                  colors: colors,
                  begin: begin,
                  end: end,
                );
                break;
              case 'radial':
                gradient = RadialGradient(
                  colors: colors,
                  center: center,
                  radius: 1.0,
                );
                break;
              case 'sweep':
                gradient = SweepGradient(
                  colors: colors,
                  center: center,
                );
                break;
              default:
                gradient = LinearGradient(
                  colors: colors,
                  begin: begin,
                  end: end,
                );
            }
          }

          addDrawable(Rectangle(
            topLeft: Offset(topLeftX, topLeftY),
            bottomRight: Offset(bottomRightX, bottomRightY),
            borderColor: borderColor,
            fillColor: fillColor,
            borderWidth: borderWidth,
            gradient: gradient,
          ));
        } else {
          print("Missing rectangle properties: $parameters");
        }
        break;

      case 'draw_text':
        if (parameters['text'] != null &&
            parameters['x'] != null &&
            parameters['y'] != null) {
          final text = parameters['text'] as String;
          final x = parseDouble(parameters['x']);
          final y = parseDouble(parameters['y']);
          
          Color color = Colors.black;
          double fontSize = 14.0;
          String fontFamily = 'Roboto';
          FontStyle fontStyle = FontStyle.normal;
          FontWeight fontWeight = FontWeight.normal;

          if (parameters['color'] != null) {
            final c = parameters['color'];
            color = Color.fromARGB(
              (parseDouble(c['a'] ?? 1) * 255).toInt(),
              (parseDouble(c['r'] ?? 0) * 255).toInt(),
              (parseDouble(c['g'] ?? 0) * 255).toInt(),
              (parseDouble(c['b'] ?? 0) * 255).toInt(),
            );
          }

          if (parameters['fontSize'] != null) {
            fontSize = parseDouble(parameters['fontSize']);
          }

          if (parameters['fontFamily'] != null) {
            fontFamily = parameters['fontFamily'] as String;
          }

          if (parameters['fontStyle'] != null) {
            fontStyle = parameters['fontStyle'] == 'italic' 
              ? FontStyle.italic 
              : FontStyle.normal;
          }

          if (parameters['fontWeight'] != null) {
            fontWeight = parameters['fontWeight'] == 'bold' 
              ? FontWeight.bold 
              : FontWeight.normal;
          }

          addDrawable(TextElement(
            text: text,
            position: Offset(x, y),
            color: color,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontStyle: fontStyle,
            fontWeight: fontWeight,
          ));
        } else {
          print("Missing text properties: $parameters");
        }
        break;

      default:
        print("Unknown function call: ${fixedJson['name']}");
    }
  }
}
