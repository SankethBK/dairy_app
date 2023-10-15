import 'package:dairy_app/core/constants/exports.dart';
import 'package:dairy_app/features/auth/presentation/bloc/user_config/user_config_cubit.dart';
import 'package:dairy_app/features/notes/core/exports.dart';
import 'package:dairy_app/features/notes/presentation/widgets/note_date_time_picker.dart';

class NoteCreatePage extends StatefulWidget {
  // display page growing animation
  static String get routeThroughHome => '/note-create-though-home';

  // display fade transition animation
  static String get routeThroughNoteReadOnly =>
      '/note-create-through-note-read-only';

  const NoteCreatePage({Key? key}) : super(key: key);

  @override
  State<NoteCreatePage> createState() => _NoteCreatePageState();
}

class _NoteCreatePageState extends State<NoteCreatePage> {
  late bool _isInitialized = false;
  late final NotesBloc notesBloc;
  late Image neonImage;
  late double topPadding = 0;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
  }

  void _initSaveTimer() {
    final userConfigCubit = BlocProvider.of<UserConfigCubit>(context);
    final isAutoSaveEnabled =
        userConfigCubit.state.userConfigModel?.isAutoSaveEnabled ?? false;

    if (isAutoSaveEnabled) {
      const int saveDelayInSeconds = 10; // delay in seconds
      _saveTimer =
          Timer.periodic(const Duration(seconds: saveDelayInSeconds), (timer) {
        notesBloc.add(AutoSaveNote());
      });
    }
  }

  @override
  void didChangeDependencies() {
    if (!_isInitialized) {
      notesBloc = BlocProvider.of<NotesBloc>(context);
      _initSaveTimer();
      // it is definitely a new note if we reached this page and the state is still NoteDummyState
      if (notesBloc.state is NoteDummyState) {
        notesBloc.add(const InitializeNote());
      }

      final backgroundImagePath = Theme.of(context)
          .extension<AuthPageThemeExtensions>()!
          .backgroundImage;

      neonImage = Image.asset(backgroundImagePath);

      precacheImage(neonImage.image, context);
      topPadding =
          MediaQuery.of(context).padding.top + AppBar().preferredSize.height;

      _isInitialized = true;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath =
        Theme.of(context).extension<AuthPageThemeExtensions>()!.backgroundImage;

    final fallbackColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .fallbackColor;

    return WillPopScope(
      onWillPop: () async {
        bool? result = await showCloseDialog(context);

        if (result == true) {
          notesBloc.add(RefreshNote());
          return true;
        }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: GlassAppBar(
          automaticallyImplyLeading: false,
          leading: NotesCloseButton(onNotesClosed: _closeAfterAutoSave),
          actions: const [
            NoteSaveButton(),
            DateTimePicker(),
            ToggleReadWriteButton(pageName: PageName.NoteCreatePage)
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: fallbackColor,
            image: DecorationImage(
              image: AssetImage(
                backgroundImagePath,
              ),
              fit: BoxFit.cover,
              alignment: const Alignment(0.725, 0.1),
            ),
          ),
          padding: EdgeInsets.only(
            top: topPadding, left: 10.0, right: 10.0,
            // bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: BlocListener<NotesBloc, NotesState>(
            bloc: notesBloc,
            listener: (context, state) {
              if (state is NoteFetchFailed) {
                showToast(AppLocalizations.of(context).failedToFetchNote);
              } else if (state is NotesSavingFailed) {
                showToast(AppLocalizations.of(context).failedToSaveNote);
              } else if (state is NoteSavedSuccesfully) {
                showToast(state.newNote!
                    ? AppLocalizations.of(context).noteSavedSuccessfully
                    : AppLocalizations.of(context).noteUpdatedSuccessfully);
                _routeToHome();
              }
            },
            child: Column(
              children: [
                BlocBuilder<NotesBloc, NotesState>(
                  bloc: notesBloc,
                  buildWhen: (previousState, state) {
                    return previousState.title != state.title;
                  },
                  builder: (context, state) {
                    void _onTitleChanged(String title) {
                      notesBloc.add(UpdateNote(title: title));
                    }

                    if (!state.safe) {
                      return NoteTitleInputField(
                          initialValue: "", onTitleChanged: _onTitleChanged);
                    }
                    return NoteTitleInputField(
                      initialValue: state.title!,
                      onTitleChanged: _onTitleChanged,
                    );
                  },
                ),
                BlocBuilder<NotesBloc, NotesState>(
                  bloc: notesBloc,
                  buildWhen: (previousState, state) {
                    return previousState is NoteDummyState;
                  },
                  builder: (context, state) {
                    return RichTextEditor(
                      controller: state.controller,
                    );
                  },
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom == 0
                      ? 10
                      : MediaQuery.of(context).viewInsets.bottom + 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _closeAfterAutoSave() {
    notesBloc.add(FetchNote());
    _routeToHome();
  }

  void _routeToHome() {
    _saveTimer?.cancel();
    notesBloc.add(RefreshNote());
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
