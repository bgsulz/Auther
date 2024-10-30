import '../auther_widgets/countdown.dart';
import '../state.dart';
import 'package:flutter/material.dart';

class AutherAppBar extends StatefulWidget {
  const AutherAppBar({
    super.key,
    required this.context,
    required this.appState,
  });

  final BuildContext context;
  final AutherState appState;

  @override
  State<AutherAppBar> createState() => _AutherAppBarState();
}

class _AutherAppBarState extends State<AutherAppBar> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: 200.0,
      collapsedHeight: 56 + (_isSearching ? 8 : 0),
      flexibleSpace: FlexibleSpaceBar(
        title: !_isSearching ? Text('Auther') : Text(''),
      ),
      actions: _isSearching ? _buildSearchBar(context) : _buildIcons(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: CountdownBar(),
      ),
    );
  }

  List<Widget> _buildSearchBar(BuildContext context) {
    return [
      SizedBox(width: 16),
      Expanded(
        child: TextField(
          onChanged: (value) => widget.appState.notifyManual(),
          controller: widget.appState.searchController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Search for a code',
            hintStyle: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            widget.appState.searchController.clear();
            _isSearching = false;
          });
        },
      ),
      SizedBox(width: 8),
    ];
  }

  List<Widget> _buildIcons() {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Search for a code',
        onPressed: () {
          widget.appState.searchController.clear();
          setState(() {
            _isSearching = true;
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        onPressed: () {
          Navigator.pushNamed(context, '/codes/settings');
        },
      ),
      IconButton(
        icon: const Icon(Icons.qr_code),
        tooltip: 'Show QR code',
        onPressed: () {
          Navigator.pushNamed(context, '/codes/qr');
        },
      ),
    ];
  }
}
