import 'package:http/http.dart' as http;

void main() async {
  var url = Uri.parse('https://siladesbeng.inovasia.site/storage/gas/ISM7mFE37G8LD5AxRRzhQBUyXVoWIuRTAJxCCCy0.png');
  var res = await http.get(url, headers: {
    'Referer': 'https://siladesbeng.inovasia.site/',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
  });
  
  print('Status: ${res.statusCode}');
  print('Content-Type: ${res.headers['content-type']}');
  print('Body Length: ${res.bodyBytes.length}');
}
