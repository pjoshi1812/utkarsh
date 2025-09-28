import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/media_model.dart';
import '../services/explore_service.dart';

class AdminExploreManagementScreen extends StatefulWidget {
  const AdminExploreManagementScreen({super.key});

  @override
  State<AdminExploreManagementScreen> createState() => _AdminExploreManagementScreenState();
}

class _AdminExploreManagementScreenState extends State<AdminExploreManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = ExploreService();

  // Form controllers
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  Uint8List? _fileBytes;
  String? _fileName;
  Uint8List? _thumbBytes;
  String? _thumbName;
  bool _isUploading = false;
  double _progress = 0;

  // Branch form controllers
  final _branchNameCtl = TextEditingController();
  final _branchAddressCtl = TextEditingController();
  final _branchPhoneCtl = TextEditingController();
  final _branchEmailCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  Widget _buildToppersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Topper'),
              onPressed: _showAddTopperDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('toppers')
                .orderBy('year', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No toppers yet'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final t = d.data();
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text('${t['studentName']} • Rank ${t['rank']} • ${t['percentage']}%'),
                    subtitle: Text('${t['standard']} ${t['board']} • Year ${t['year']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('toppers').doc(d.id).delete();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBranchesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.location_city, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Add Branch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _branchNameCtl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _branchAddressCtl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _branchPhoneCtl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _branchEmailCtl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Branch'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_branchNameCtl.text.trim().isEmpty || _branchAddressCtl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name and address')));
                      return;
                    }
                    await FirebaseFirestore.instance.collection('branches').add({
                      'name': _branchNameCtl.text.trim(),
                      'address': _branchAddressCtl.text.trim(),
                      'phone': _branchPhoneCtl.text.trim(),
                      'email': _branchEmailCtl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    _branchNameCtl.clear();
                    _branchAddressCtl.clear();
                    _branchPhoneCtl.clear();
                    _branchEmailCtl.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch saved'), backgroundColor: Colors.green));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('branches')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No branches yet'));
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data();
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.location_on, color: Colors.green),
                    title: Text(data['name'] ?? ''),
                    subtitle: Text('${data['address'] ?? ''}\n${data['phone'] ?? ''}  ${data['email'] ?? ''}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('branches').doc(d.id).delete();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTopperDialog() {
    String standard = '12th';
    String board = 'HSC';
    final yearCtl = TextEditingController(text: DateTime.now().year.toString());
    final rankCtl = TextEditingController();
    final percCtl = TextEditingController();
    String? selectedStudentName;
    String? selectedEnrollmentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Add Topper', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: standard,
                          decoration: const InputDecoration(labelText: 'Standard'),
                          items: const [
                            DropdownMenuItem(value: '12th', child: Text('12th')),
                            DropdownMenuItem(value: '10th', child: Text('10th')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              standard = v ?? '12th';
                              // Reset board default based on standard
                              board = standard == '12th' ? 'HSC' : 'SSC';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: board,
                          decoration: const InputDecoration(labelText: 'Board'),
                          items: [
                            ...(standard == '12th'
                                ? const [
                                    DropdownMenuItem(value: 'HSC', child: Text('HSC')),
                                    DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                                  ]
                                : const [
                                    DropdownMenuItem(value: 'SSC', child: Text('SSC')),
                                    DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                                  ]),
                          ],
                          onChanged: (v) {
                            setState(() { board = v ?? 'SSC'; });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: yearCtl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Year (e.g., 2024)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Select Student (${standard})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: (() {
                        // Try to filter on server if fields exist; otherwise fetch all and filter client-side
                        final col = FirebaseFirestore.instance.collection('enrollments');
                        // We don't know schema presence; start with full and filter client-side safely
                        return col.snapshots();
                      })(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                        final docs = snap.data!.docs;
                        // Client-side filtering with graceful fallbacks
                        final int desiredYear = int.tryParse(yearCtl.text.trim()) ?? DateTime.now().year;
                        final filtered = docs.where((d) {
                          final data = d.data();
                          final course = (data['course'] ?? '').toString().toLowerCase();
                          final stdOk = standard == '12th' ? course.contains('12') : course.contains('10');

                          // optional board/year fields if present in enrollment/user
                          final boardField = (data['board'] ?? data['Board'] ?? '').toString().toUpperCase();
                          final yearFieldRaw = data['year'] ?? data['academicYear'] ?? data['batchYear'];
                          final yearField = yearFieldRaw is num
                              ? yearFieldRaw.toInt()
                              : int.tryParse((yearFieldRaw ?? '').toString()) ?? desiredYear;

                          final boardOk = boardField.isEmpty ? true : boardField == board.toUpperCase();
                          final yearOk = yearField == desiredYear;

                          return stdOk && boardOk && yearOk;
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(child: Text('No students found for selected Standard/Board/Year.'));
                        }
                        return ListView.builder(
                          controller: controller,
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final d = filtered[i];
                            final data = d.data();
                            final name = data['studentName'] ?? data['name'] ?? 'Unknown';
                            final sub = data['course'] ?? '${standard} - ${board}';
                            final selected = d.id == selectedEnrollmentId;
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(sub.toString()),
                              trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                              onTap: () {
                                selectedEnrollmentId = d.id;
                                selectedStudentName = name;
                                setState(() {});
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: rankCtl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rank'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: percCtl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Percentage'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Topper'),
                      onPressed: () async {
                        if (selectedStudentName == null || rankCtl.text.isEmpty || percCtl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a student and fill rank and percentage.')),
                          );
                          return;
                        }
                        final rank = int.tryParse(rankCtl.text.trim()) ?? 0;
                        final percentage = num.tryParse(percCtl.text.trim()) ?? 0;
                        final parsedYear = int.tryParse(yearCtl.text.trim()) ?? DateTime.now().year;
                        await ExploreService().addTopper(
                          studentName: selectedStudentName!,
                          standard: standard,
                          board: board,
                          year: parsedYear,
                          rank: rank,
                          percentage: percentage,
                          enrollmentId: selectedEnrollmentId,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Topper saved'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtl.dispose();
    _descCtl.dispose();
    _branchNameCtl.dispose();
    _branchAddressCtl.dispose();
    _branchPhoneCtl.dispose();
    _branchEmailCtl.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool thumbnail}) async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.any);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (thumbnail) {
          _thumbBytes = result.files.single.bytes!;
          _thumbName = result.files.single.name;
        } else {
          _fileBytes = result.files.single.bytes!;
          _fileName = result.files.single.name;
        }
      });
    }
  }

  Future<void> _submit(String category) async {
    if (_titleCtl.text.isEmpty || _descCtl.text.isEmpty || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a file.')),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _progress = 0;
      });

      // Infer content type
      String? contentType;
      if (_fileName != null) {
        final lower = _fileName!.toLowerCase();
        if (lower.endsWith('.mp4')) contentType = 'video/mp4';
        if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) contentType = 'image/jpeg';
        if (lower.endsWith('.png')) contentType = 'image/png';
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'explore/$category/$now-${_fileName ?? 'file'}';
      final url = await _service.uploadBytes(
        bytes: _fileBytes!,
        storagePath: storagePath,
        contentType: contentType,
        onProgress: (p) => setState(() => _progress = p),
      );

      String thumbUrl = '';
      if (_thumbBytes != null) {
        final thumbPath = 'explore/$category/$now-thumb-${_thumbName ?? 'thumb'}';
        thumbUrl = await _service.uploadBytes(
          bytes: _thumbBytes!,
          storagePath: thumbPath,
          contentType: 'image/jpeg',
          onProgress: (p) => setState(() => _progress = p),
        );
      }

      final isVideo = (contentType?.startsWith('video/') ?? false);
      final media = MediaModel(
        id: '',
        title: _titleCtl.text.trim(),
        description: _descCtl.text.trim(),
        url: url,
        thumbnailUrl: thumbUrl,
        type: isVideo ? 'video' : 'image',
        duration: null,
        createdAt: DateTime.now(),
        category: category,
      );

      await _service.upsertMedia(media);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully'), backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _resetForm() {
    _titleCtl.clear();
    _descCtl.clear();
    _fileBytes = null;
    _fileName = null;
    _thumbBytes = null;
    _thumbName = null;
    _progress = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Explore Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'Demo Videos'),
            Tab(icon: Icon(Icons.menu_book), text: 'Pamphlets'),
            Tab(icon: Icon(Icons.flag), text: 'Banners'),
            Tab(icon: Icon(Icons.collections), text: 'Media'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Toppers'),
            Tab(icon: Icon(Icons.location_city), text: 'Branches'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset('assets/bg_math.png', fit: BoxFit.cover),
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _buildTab(category: 'demo_video'),
              _buildTab(category: 'pamphlet'),
              _buildTab(category: 'banner'),
              _buildTab(category: 'general'),
              _buildToppersTab(),
              _buildBranchesTab(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String category}) {
    return Column(
      children: [
        _buildForm(category),
        Expanded(child: _buildList(category)),
      ],
    );
  }

  Widget _buildForm(String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.add, color: Colors.green),
              const SizedBox(width: 8),
              Text('Add ${category.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickFile(thumbnail: false),
                  icon: const Icon(Icons.attach_file),
                  label: Text(_fileName ?? 'Select file (image/video)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickFile(thumbnail: true),
                  icon: const Icon(Icons.image),
                  label: Text(_thumbName ?? 'Select thumbnail (image)'),
                ),
              ),
            ],
          ),
          if (_isUploading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress > 0 && _progress < 1 ? _progress : null),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _submit(category),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String category) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('media')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No items yet'));
        }
        // Sort client-side by createdAt desc
        final items = docs
            .map((d) => MediaModel.fromJson(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final media = items[i];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: CircleAvatar(backgroundImage: media.thumbnailUrl.isNotEmpty ? NetworkImage(media.thumbnailUrl) : null,
                child: media.thumbnailUrl.isEmpty ? const Icon(Icons.image) : null,
              ),
              title: Text(media.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(media.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('media').doc(media.id).delete();
                },
              ),
            );
          },
        );
      },
    );
  }
}
