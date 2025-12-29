import 'package:flutter/material.dart';

class TagPeopleCard extends StatefulWidget {
  final List<String> groupMembers;
  final Function(List<String>)? onTagsChanged;
  final String? currentUsername; // Add current username for validation

  const TagPeopleCard({
    super.key,
    required this.groupMembers,
    this.onTagsChanged,
    this.currentUsername, // Add this parameter
  });

  @override
  State<TagPeopleCard> createState() => _TagPeopleCardState();
}

class _TagPeopleCardState extends State<TagPeopleCard> {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _taggedPeople = [];
  List<String> _filteredMembers = [];
  String? _errorMessage; // To show validation errors

  void _filterSuggestions(String value) {
    // Clear error message when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    if (value.endsWith('@')) {
      // Start showing all members when '@' is typed
      _filteredMembers = widget.groupMembers;
    } else if (value.contains('@')) {
      String query = value.split('@').last.toLowerCase();
      _filteredMembers = widget.groupMembers
          .where((member) => member.toLowerCase().contains(query))
          .toList();
    } else {
      _filteredMembers = [];
    }
    setState(() {});
  }

  void _addTag(String member) {
    // Clear previous error message
    setState(() {
      _errorMessage = null;
    });

    // Prevent self-tagging
    if (widget.currentUsername != null && member == widget.currentUsername) {
      setState(() {
        _errorMessage = 'You cannot tag yourself';
      });
      return;
    }

    if (!_taggedPeople.contains(member)) {
      setState(() {
        _taggedPeople.add(member);
        _tagController.text = _tagController.text.replaceAll(
          RegExp(r'@\w*$'),
          '@$member ',
        );
        _filteredMembers = [];
      });
      widget.onTagsChanged?.call(_taggedPeople);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 5, color: Colors.black12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tag People",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Show error message if any
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],

          // Tag input field
          TextField(
            controller: _tagController,
            decoration: InputDecoration(
              hintText: 'Type @ to tag group members',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 1),
              ),
            ),
            onChanged: _filterSuggestions,
          ),

          // Show suggestions
          if (_filteredMembers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _filteredMembers
                  .map(
                    (member) => ActionChip(
                      label: Text(member),
                      onPressed: () => _addTag(member),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Show selected tags
          if (_taggedPeople.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _taggedPeople
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _taggedPeople.remove(tag);
                        });
                        widget.onTagsChanged?.call(_taggedPeople);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
