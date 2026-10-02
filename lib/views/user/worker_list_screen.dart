import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'worker_detail_screen.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_room_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class WorkerListScreen extends ConsumerStatefulWidget {
  final String serviceType;
  final IconData serviceIcon;

  const WorkerListScreen({
    super.key,
    required this.serviceType,
    required this.serviceIcon,
  });

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen> {
  String _selectedFilter = 'Available Now';

  static const _filters = [
    {'label': 'Available Now', 'icon': Icons.circle, 'color': Colors.green},
    {'label': 'Low Price',     'icon': Icons.attach_money, 'color': Color(0xFF4CAF50)},
    {'label': 'Top Rated',     'icon': Icons.star_rounded, 'color': Color(0xFFFF9800)},
    {'label': 'Nearest',       'icon': Icons.near_me_rounded, 'color': Color(0xFF2196F3)},
  ];

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersByServiceProvider(widget.serviceType));

    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceType)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final label = filter['label'] as String;
                final icon  = filter['icon']  as IconData;
                final color = filter['color'] as Color;
                final isSelected = _selectedFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    avatar: Icon(icon, size: 16,
                        color: isSelected ? color : Colors.grey),
                    label: Text(label),
                    onSelected: (_) => setState(() => _selectedFilter = label),
                    selectedColor: color.withValues(alpha: 0.15),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      color: isSelected ? color : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                    side: BorderSide(
                      color: isSelected ? color : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(workersByServiceProvider(widget.serviceType));
              },
              child: workersAsync.when(
            data: (workers) {
              List<WorkerModel> displayList = List.from(workers);

              if (_selectedFilter == 'Available Now') {
                displayList = displayList
                    .where((w) => w.availability)
                    .toList();
              } else if (_selectedFilter == 'Top Rated') {
                displayList.sort((a, b) => b.rating.compareTo(a.rating));
              } else if (_selectedFilter == 'Low Price') {
                displayList.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
              } else if (_selectedFilter == 'Nearest') {
                // Sort by location string alphabetically as a proxy;
                // workers with empty location go last
                displayList.sort((a, b) {
                  if (a.location.isEmpty) return 1;
                  if (b.location.isEmpty) return -1;
                  return a.location.compareTo(b.location);
                });
              }

              if (displayList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.serviceIcon, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No ${widget.serviceType} found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check back later or change filter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final worker = displayList[index];
                      return _WorkerCard(
                        worker: worker,
                        activeFilter: _selectedFilter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerDetailScreen(worker: worker),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CustomLoadingIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
        ),
      ],
      ),
    );
  }
}

class _WorkerCard extends ConsumerWidget {
  final WorkerModel worker;
  final VoidCallback onTap;
  final String activeFilter;

  const _WorkerCard({
    required this.worker,
    required this.onTap,
    required this.activeFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Badge shown based on active filter
    Widget? filterBadge;
    if (activeFilter == 'Low Price' && worker.hourlyRate > 0) {
      filterBadge = _Badge(
        icon: Icons.attach_money,
        label: 'Rs ${worker.hourlyRate.toInt()}/hr',
        color: const Color(0xFF4CAF50),
      );
    } else if (activeFilter == 'Top Rated' && worker.rating > 0) {
      filterBadge = _Badge(
        icon: Icons.star_rounded,
        label: '${worker.rating.toStringAsFixed(1)} ★',
        color: const Color(0xFFFF9800),
      );
    } else if (activeFilter == 'Nearest' && worker.location.isNotEmpty) {
      filterBadge = _Badge(
        icon: Icons.near_me_rounded,
        label: worker.location,
        color: const Color(0xFF2196F3),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (filterBadge != null) ...[
                filterBadge,
                const SizedBox(height: 10),
              ],
              Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: worker.profileImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(worker.profileImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    ),
                    child: worker.profileImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: Color(0xFFFF9800),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: worker.availability ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF9800,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                worker.rating > 0
                                    ? worker.rating.toStringAsFixed(1)
                                    : 'New',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      worker.skills.isEmpty
                          ? 'General ${worker.serviceType} services'
                          : worker.skills,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.work_history_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            worker.experience.isEmpty
                                ? 'New Worker'
                                : worker.experience,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            worker.location.isEmpty
                                ? 'Location N/A'
                                : worker.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFFFF9800),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFFF9800,
                      ).withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () async {
                      final userProfile = ref
                          .read(userProfileProvider)
                          .valueOrNull;
                      if (userProfile == null) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) =>
                            const Center(child: CustomLoadingIndicator()),
                      );

                      try {
                        final chat = await FirestoreService().createOrGetChat(
                          userId: userProfile.userId,
                          workerId: worker.workerId,
                          userName: userProfile.name,
                          userImage: userProfile.profileImage,
                          workerName: worker.name,
                          workerImage: worker.profileImage,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // close loader
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                chatId: chat.chatId,
                                chatTitle: worker.name,
                                chatImage: worker.profileImage,
                                isWorker: false,
                                currentUserId: userProfile.userId,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // close loader
                        }
                      }
                    },
                  ),
                ],
              ), // close chat button Column
            ], // close outer Row children
          ), // close outer Row
            ], // close Padding Column children
          ), // close Padding Column
        ), // close Padding
      ), // close InkWell
    ); // close Container
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
