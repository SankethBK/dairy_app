import 'package:dairy_app/app/themes/theme_extensions/auth_page_theme_extensions.dart';
import 'package:dairy_app/app/themes/theme_extensions/home_page_theme_extensions.dart';
import 'package:dairy_app/app/themes/theme_extensions/note_create_page_theme_extensions.dart';
import 'package:dairy_app/core/utils/utils.dart';
import 'package:dairy_app/core/widgets/glass_app_bar.dart';
import 'package:dairy_app/core/widgets/glassmorphism_cover.dart';
import 'package:dairy_app/features/notes/domain/entities/notes.dart';
import 'package:dairy_app/features/notes/presentation/bloc/notes/notes_bloc.dart';
import 'package:dairy_app/features/notes/presentation/bloc/notes_fetch/notes_fetch_cubit.dart';
import 'package:dairy_app/features/notes/presentation/mixins/note_helper_mixin.dart';
import 'package:dairy_app/features/notes/presentation/widgets/note_read_button.dart';
import 'package:dairy_app/features/notes/presentation/widgets/note_save_button.dart';
import 'package:dairy_app/features/notes/presentation/widgets/note_tags.dart';
import 'package:dairy_app/features/notes/presentation/widgets/read_only_editor.dart';
import 'package:dairy_app/features/notes/presentation/widgets/toggle_read_write_button.dart';
import 'package:dairy_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../widgets/notes_close_button.dart';

class NotesReadOnlyPage extends StatefulWidget {
  // display open container animation
  static String get routeThroughHome => '/note-read-page-through-home';
  final String? id;

  // display fade transition animaiton
  static String get routeThoughNotesCreate =>
      '/note-read-page-though-note-create-page';

  const NotesReadOnlyPage({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<NotesReadOnlyPage> createState() => _NotesReadOnlyPageState();
}

class _NotesReadOnlyPageState extends State<NotesReadOnlyPage>
    with NoteHelperMixin {
  late bool _isInitialized = false;
  late final NotesBloc notesBloc;
  late Image neonImage;
  late double topPadding;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (!_isInitialized) {
      notesBloc = BlocProvider.of<NotesBloc>(context);
      if (notesBloc.state is NoteDummyState) {
        notesBloc.add(InitializeNote(id: widget.id));
      }

      final _notesFetchCubit = BlocProvider.of<NotesFetchCubit>(context);

      final _notePreviewList = _notesFetchCubit.state.notePreviewList;

      // Find the index of the current note based on the ID to set it as _initialPageIndex
      var _initialPageIndex =
          _notePreviewList.indexWhere((note) => note.id == widget.id);

      // If the note is not found, default to the first page (index 0)
      if (_initialPageIndex == -1) {
        _initialPageIndex = 0;
      }

      // Initialize the PageController with the found index
      _pageController = PageController(initialPage: _initialPageIndex);

      final backgroundImagePath = Theme.of(context)
          .extension<AuthPageThemeExtensions>()!
          .backgroundImage;

      neonImage = Image.asset(backgroundImagePath);

      precacheImage(neonImage.image, context);

      topPadding = MediaQuery.of(context).padding.top +
          AppBar().preferredSize.height +
          10;
      _isInitialized = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final notesBloc = BlocProvider.of<NotesBloc>(context);

    final _notesFetchCubit = BlocProvider.of<NotesFetchCubit>(context);

    final _notePreviewList = _notesFetchCubit.state.notePreviewList;

    final backgroundImagePath =
        Theme.of(context).extension<AuthPageThemeExtensions>()!.backgroundImage;
    return WillPopScope(
      onWillPop: () => handleWillPop(context, notesBloc),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: GlassAppBar(
            automaticallyImplyLeading: false,
            actions: const <Widget>[
              NoteSaveButton(),
              NoteReadIconButton(),
              ToggleReadWriteButton(pageName: PageName.NoteReadOnlyPage),
            ],
            leading: NotesCloseButton(onNotesClosed: _routeToHome),
          ),
          body: Container(
            padding: EdgeInsets.only(
              top: topPadding,
              left: 10.0,
              right: 10.0,
              bottom: 10.0,
            ),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  backgroundImagePath,
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: widget.id != null
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: _notePreviewList.length,
                    onPageChanged: (pageIndex) {
                      // PageView has snapped, load the note for the current pageIndex
                      final _notePreview = _notePreviewList[pageIndex];

                      notesBloc.add(InitializeNote(id: _notePreview.id));
                    },
                    itemBuilder: (context, pageIndex) {
                      final _notePreview = _notePreviewList[pageIndex];

                      // Don't refresh the bloc if the current note is already edited
                      if (notesBloc.state is! NoteUpdatedState) {
                        notesBloc.add(InitializeNote(id: _notePreview.id));
                      }

                      return readOnlyEditor(
                        notePreview: _notePreview,
                      );
                    },
                  )
                : readOnlyEditor(),
          ),
        ),
      ),
    );
  }

  Widget readOnlyEditor({
    NotePreview? notePreview,
  }) {
    final notesBloc = BlocProvider.of<NotesBloc>(context);

    final richTextGradientStartColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .richTextGradientStartColor;

    final richTextGradientEndColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .richTextGradientEndColor;

    final mainTextColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .mainTextColor;

    final dateColor =
        Theme.of(context).extension<HomePageThemeExtensions>()!.dateColor;

    final borderColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .titleTextBoxBorderColor;

    return BlocListener<NotesBloc, NotesState>(
      bloc: notesBloc,
      listener: (context, state) {
        if (state is NoteFetchFailed) {
          showToast(S.current.failedToFetchNote);
        } else if (state is NotesSavingFailed) {
          showToast(S.current.failedToSaveNote);
        } else if (state is NoteSavedSuccesfully) {
          showToast(state.newNote!
              ? S.current.noteSavedSuccessfully
              : S.current.noteUpdatedSuccessfully);
          _routeToHome();
        }
      },
      child: GlassMorphismCover(
        displayShadow: false,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 5),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
            gradient: LinearGradient(
              colors: [
                richTextGradientStartColor,
                richTextGradientEndColor,
              ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
          ),
          child: BlocBuilder<NotesBloc, NotesState>(
            bloc: notesBloc,
            buildWhen: (previousState, currentState) {
              if (currentState.safe) {
                // Rebuild only if the note in the bloc matches the note ID of this page
                if (notePreview != null) {
                  return currentState.id == notePreview.id;
                }

                return true;
              }
              return false; // Don't rebuild for other states or mismatched note IDs
            },
            builder: (context, state) {
              if (state.safe) {
                return ListView(
                  padding: const EdgeInsets.only(top: 10),
                  children: [
                    Text(state.title ?? 'Null title',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20.0,
                          color: mainTextColor,
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat.yMMMEd().format(state.createdAt!),
                          style: TextStyle(
                            color: dateColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat.jm().format(state.createdAt!),
                          style: TextStyle(
                            color: dateColor,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    NoteTags(tags: state.tags ?? []),
                    const SizedBox(height: 20),
                    ReadOnlyEditor(
                      controller: state.controller,
                    )
                  ],
                );
              }
              return Container();
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _routeToHome() {
    notesBloc.add(RefreshNote());
    Navigator.of(context).pop();
  }
}
