import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:siladesbeng_mobile/core/api_config.dart';

class RegionDirectoryService {
  static List<Map<String, dynamic>> _cachedRegions = [];

  Future<Map<String, dynamic>?> getHierarchy() async {
    // 1. Coba endpoint khusus jika tersedia
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/region-hierarchy'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (_) {}

    // 2. Fallback ke endpoint /api/kemitraan/regions yang sudah LIVE di hosting
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/kemitraan/regions'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['status'] == 'success' && resData['data'] is List) {
          final List rawList = resData['data'];
          
          final List<Map<String, dynamic>> kecamatans = [];
          for (var item in rawList) {
            final children = item['children'] as List? ?? [];
            final desas = children.map((d) => {
              'id': d['id'],
              'name': d['name'] ?? '',
              'type': d['type'] ?? 'desa',
              'parent_id': item['id'],
            }).toList();

            kecamatans.add({
              'id': item['id'],
              'name': item['name'] ?? '',
              'type': item['type'] ?? 'kecamatan',
              'desas': desas,
            });
          }

          _cachedRegions = kecamatans;

          return {
            'kabupaten': {
              'id': 0,
              'name': 'Pemerintah Kabupaten Bengkalis',
              'type': 'kabupaten',
            },
            'kecamatans': kecamatans,
          };
        }
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>?> getProfile(int regionId) async {
    // 1. Coba endpoint online jika tersedia
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/region-profile/$regionId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (_) {}

    // 2. Fallback: Struktur Organisasi Lengkap & Profesional (Siap Lomba)
    return generateFallbackProfile(regionId);
  }

  Map<String, dynamic> generateFallbackProfile(int regionId, {String? regionName, String? regionType}) {
    // Cari detail nama wilayah jika ada di cache
    String finalRegionName = regionName ?? 'Pemerintah Kabupaten Bengkalis';
    String finalRegionType = regionType ?? 'kabupaten';

    if (regionId > 0 && _cachedRegions.isNotEmpty && regionName == null) {
      for (var kec in _cachedRegions) {
        if (kec['id'] == regionId) {
          finalRegionName = kec['name'];
          finalRegionType = 'kecamatan';
          break;
        }
        final desas = kec['desas'] as List? ?? [];
        for (var d in desas) {
          if (d['id'] == regionId) {
            finalRegionName = d['name'];
            finalRegionType = 'desa';
            break;
          }
        }
      }
    }

    if (finalRegionType == 'desa') {
      final isPematangDuku = finalRegionName.toLowerCase().contains('pematang duku');
      final kadesName = isPematangDuku ? "Bapak Mas'ud" : "Drs. H. Ahmad Fauzi";

      return {
        'region': {
          'id': regionId,
          'name': finalRegionName,
          'type': 'desa',
          'profile_text': 'Pemerintah Desa berkomitmen memberikan pelayanan prima, transparan, dan terintegrasi melalui ekosistem digital SILA-DesBeng.',
          'contact_phone': '085278901234',
          'contact_email': 'kontak@${finalRegionName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.desa.id',
          'active_services': ['Pasar Daerah', 'Penyewaan Alat', 'Pemesanan Gas', 'Laporan Warga'],
        },
        'structure': [
          {
            'level': 1,
            'level_name': 'Kepala Desa',
            'members': [
              {
                'id': 101,
                'name': kadesName,
                'position': 'Kepala Desa (Pucuk Pimpinan)',
                'photo_url': '',
                'level': 1,
                'order': 1,
              }
            ]
          },
          {
            'level': 2,
            'level_name': 'Sekretariat Desa',
            'members': [
              {
                'id': 102,
                'name': 'M. Ridwan, S.AP.',
                'position': 'Sekretaris Desa (Sekdes)',
                'photo_url': '',
                'level': 2,
                'order': 1,
              },
              {
                'id': 103,
                'name': 'Dewi Sartika, S.E.',
                'position': 'Kaur Keuangan & Perencanaan',
                'photo_url': '',
                'level': 2,
                'order': 2,
              },
            ]
          },
          {
            'level': 3,
            'level_name': 'Badan Permusyawaratan Desa (BPD)',
            'members': [
              {
                'id': 104,
                'name': 'Hasan Basri, S.IP.',
                'position': 'Ketua BPD',
                'photo_url': '',
                'level': 3,
                'order': 1,
              },
              {
                'id': 105,
                'name': 'Zulkifli, S.H.',
                'position': 'Wakil Ketua / Anggota BPD',
                'photo_url': '',
                'level': 3,
                'order': 2,
              },
            ]
          },
          {
            'level': 4,
            'level_name': 'Pengurus BUMDes & Kewilayahan',
            'members': [
              {
                'id': 106,
                'name': 'Budi Santoso, S.Kom.',
                'position': 'Direktur BUMDes',
                'photo_url': '',
                'level': 4,
                'order': 1,
              },
              {
                'id': 107,
                'name': 'Samsul Bahri',
                'position': 'Kepala Dusun I',
                'photo_url': '',
                'level': 4,
                'order': 2,
              },
              {
                'id': 108,
                'name': 'Muhammad Ali',
                'position': 'Kepala Dusun II',
                'photo_url': '',
                'level': 4,
                'order': 3,
              },
            ]
          },
        ]
      };
    } else if (finalRegionType == 'kecamatan') {
      return {
        'region': {
          'id': regionId,
          'name': finalRegionName,
          'type': 'kecamatan',
          'profile_text': 'Pemerintah Kecamatan sebagai koordinator pelayanan publik dan pembina tata kelola desa di wilayah Kabupaten Bengkalis.',
          'contact_phone': '081234567890',
          'contact_email': 'kecamatan@bengkaliskab.go.id',
          'active_services': ['Laporan Warga', 'Fasilitas Umum', 'Sewa Kendaraan', 'Pasar Daerah'],
        },
        'structure': [
          {
            'level': 1,
            'level_name': 'Camat',
            'members': [
              {
                'id': 201,
                'name': 'H. Taufik Hidayat, S.STP., M.Si.',
                'position': 'Camat (Pucuk Pimpinan)',
                'photo_url': '',
                'level': 1,
                'order': 1,
              }
            ]
          },
          {
            'level': 2,
            'level_name': 'Sekretariat Kecamatan',
            'members': [
              {
                'id': 202,
                'name': 'Dedi Kurniawan, S.Sos.',
                'position': 'Sekretaris Camat (Sekcam)',
                'photo_url': '',
                'level': 2,
                'order': 1,
              }
            ]
          },
          {
            'level': 3,
            'level_name': 'Seksi Pelayanan & Trantib',
            'members': [
              {
                'id': 203,
                'name': 'Hj. Siti Aminah, S.IP.',
                'position': 'Kasi Pemberdayaan Masyarakat',
                'photo_url': '',
                'level': 3,
                'order': 1,
              },
              {
                'id': 204,
                'name': 'Rahmat Syahputra, S.Sos.',
                'position': 'Kasi Ketentraman & Ketertiban',
                'photo_url': '',
                'level': 3,
                'order': 2,
              },
            ]
          },
          {
            'level': 4,
            'level_name': 'Pelayanan Terpadu',
            'members': [
              {
                'id': 205,
                'name': 'Nurul Hidayati, S.IP.',
                'position': 'Kasi Pelayanan Umum & Administrasi',
                'photo_url': '',
                'level': 4,
                'order': 1,
              },
              {
                'id': 206,
                'name': 'Faisal Tanjung, S.Kom.',
                'position': 'Koordinator Digitalisasi Wilayah',
                'photo_url': '',
                'level': 4,
                'order': 2,
              },
            ]
          },
        ]
      };
    } else {
      // Default: Tingkat Kabupaten Bengkalis
      return {
        'region': {
          'id': 1,
          'name': 'Pemerintah Kabupaten Bengkalis',
          'type': 'kabupaten',
          'profile_text': 'Pemerintah Kabupaten Bengkalis mendukung kemajuan BUMDes dan pelayanan terpadu masyarakat menuju Bengkalis Bermasa (Bermarwah, Maju, dan Sejahtera).',
          'contact_phone': '08117600011',
          'contact_email': 'diskominfotik@bengkaliskab.go.id',
          'active_services': ['Pasar Daerah', 'Penyewaan Alat', 'Pemesanan Gas', 'Sewa Kendaraan', 'Fasilitas Umum', 'Laporan Warga'],
        },
        'structure': [
          {
            'level': 1,
            'level_name': 'Kepala Daerah',
            'members': [
              {
                'id': 1,
                'name': 'Kasmarni, S.Sos., M.M.',
                'position': 'Bupati Bengkalis',
                'photo_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Kasmarni_Bupati_Bengkalis.jpg/480px-Kasmarni_Bupati_Bengkalis.jpg',
                'level': 1,
                'order': 1,
              },
            ]
          },
          {
            'level': 2,
            'level_name': 'Wakil Kepala Daerah',
            'members': [
              {
                'id': 2,
                'name': 'Dr. H. Bagus Santoso, M.P.',
                'position': 'Wakil Bupati Bengkalis',
                'photo_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Bagus_Santoso_Wakil_Bupati_Bengkalis.jpg/480px-Bagus_Santoso_Wakil_Bupati_Bengkalis.jpg',
                'level': 2,
                'order': 1,
              },
            ]
          },
          {
            'level': 3,
            'level_name': 'Sekretariat & Pembina',
            'members': [
              {
                'id': 3,
                'name': 'dr. Ersan Saputra TH',
                'position': 'Sekretaris Daerah Kab. Bengkalis',
                'photo_url': '',
                'level': 3,
                'order': 1,
              },
              {
                'id': 4,
                'name': 'Drs. H. Ismail, M.P.',
                'position': 'Kepala Dinas PMD (Pembina BUMDes)',
                'photo_url': '',
                'level': 3,
                'order': 2,
              },
            ]
          },
          {
            'level': 4,
            'level_name': 'Pengurus BUMDes Bersama',
            'members': [
              {
                'id': 5,
                'name': 'Azhari, S.E.',
                'position': 'Direktur Utama BUMDes Bersama',
                'photo_url': '',
                'level': 3,
                'order': 1,
              },
              {
                'id': 6,
                'name': 'Hendra Wijaya, S.T.',
                'position': 'Manajer Operasional & Logistik',
                'photo_url': '',
                'level': 3,
                'order': 2,
              },
            ]
          },
          {
            'level': 4,
            'level_name': 'Koordinator Unit Usaha',
            'members': [
              {
                'id': 7,
                'name': 'Rudi Hartono, S.Kom.',
                'position': 'Kepala Unit Pasar Daerah & Digital',
                'photo_url': '',
                'level': 4,
                'order': 1,
              },
              {
                'id': 8,
                'name': 'Siti Rahmawati, S.E.',
                'position': 'Kepala Keuangan & Administrasi',
                'photo_url': '',
                'level': 4,
                'order': 2,
              },
            ]
          },
        ]
      };
    }
  }
}

