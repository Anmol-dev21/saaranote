import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/flashcard_viewmodel.dart';

/// Screen for reviewing flashcards in a note
class FlashcardRevisionScreen extends StatefulWidget {
  final int noteId;

  const FlashcardRevisionScreen({
    super.key,
    required this.noteId,
  });

  @override
  State<FlashcardRevisionScreen> createState() => _FlashcardRevisionScreenState();
}

class _FlashcardRevisionScreenState extends State<FlashcardRevisionScreen> {
  @override
  void initState() {
    super.initState();
    // Load flashcards when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardViewModel>().loadFlashcards(widget.noteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Revision'),
        actions: [
          Consumer<FlashcardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.hasFlashcards) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      '${viewModel.currentIndex + 1} / ${viewModel.totalFlashcards}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FlashcardViewModel>(
        builder: (context, viewModel, child) {
          // Loading state
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage ?? 'An error occurred',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => viewModel.loadFlashcards(widget.noteId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (!viewModel.hasFlashcards) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No flashcards available',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create flashcards from your notes first',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Flashcard display
          final flashcard = viewModel.currentFlashcard;
          if (flashcard == null) {
            return const Center(child: Text('No flashcard to display'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Flashcard content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  flashcard.question,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Answer card (conditional)
                        AnimatedOpacity(
                          opacity: viewModel.showAnswer ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: viewModel.showAnswer
                              ? Card(
                                  elevation: 4,
                                  color: Colors.green[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Answer',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          flashcard.answer,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Control buttons
                _buildControlButtons(context, viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, FlashcardViewModel viewModel) {
    return Column(
      children: [
        // Show/Hide Answer button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => viewModel.toggleAnswer(),
            icon: Icon(viewModel.showAnswer ? Icons.visibility_off : Icons.visibility),
            label: Text(viewModel.showAnswer ? 'Hide Answer' : 'Show Answer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Navigation buttons
        Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: viewModel.canGoPrevious ? () => viewModel.previousCard() : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Next button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: viewModel.canGoNext ? () => viewModel.nextCard() : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
