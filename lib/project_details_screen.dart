import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Add this line
import 'project_model.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project? project;
  final void Function(Project) onSave;

  const ProjectDetailsScreen({super.key, this.project, required this.onSave});

  @override
  _ProjectDetailsScreenState createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _progressController;
  late String _projectId;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _projectId = widget.project!.id;
      _nameController = TextEditingController(text: widget.project!.name);
      _progressController =
          TextEditingController(text: widget.project!.progress.toString());
    } else {
      _projectId = const Uuid().v4(); // Ensure this uses the correct Uuid class
      _nameController = TextEditingController();
      _progressController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final progress = int.parse(_progressController.text);
      final project = Project(id: _projectId, name: name, progress: progress);
      widget.onSave(project);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _progressController,
                decoration:
                    const InputDecoration(labelText: 'Progress (0-100)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter progress';
                  }
                  final progress = int.tryParse(value);
                  if (progress == null || progress < 0 || progress > 100) {
                    return 'Please enter a valid progress between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveProject,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
