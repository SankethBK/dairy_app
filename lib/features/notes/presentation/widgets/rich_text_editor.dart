import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:dairy_app/app/themes/theme_extensions/note_create_page_theme_extensions.dart';
import 'package:dairy_app/core/widgets/glass_dialog.dart';
import 'package:dairy_app/core/widgets/glassmorphism_cover.dart';
import 'package:dairy_app/features/auth/presentation/bloc/font/font_cubit.dart';
import 'package:dairy_app/features/notes/data/models/notes_model.dart';
import 'package:dairy_app/features/notes/presentation/bloc/notes/notes_bloc.dart';
import 'package:dairy_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class RichTextEditor extends StatefulWidget {
  final QuillController? controller;

  const RichTextEditor({Key? key, required this.controller}) : super(key: key);

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return Expanded(child: GlassPaneForEditor(quillEditor: Container()));
    }

    return _buildWelcomeEditor(context);
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    var quillEditor = QuillEditor(
      // scrollPhysics: const BouncingScrollPhysics(),
      embedBuilders: [
        ...FlutterQuillEmbeds.builders(),
      ],

      controller: widget.controller!,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: false,
      readOnly: false,
      placeholder: 'Write something here...',
      expands: false,
      padding: EdgeInsets.zero,
      customStyles: DefaultStyles(
        subscript: const TextStyle(fontFamily: 'SF-UI-Display', fontFeatures: [
          FontFeature.subscripts(),
        ]),
        superscript:
            const TextStyle(fontFamily: 'SF-UI-Display', fontFeatures: [
          FontFeature.superscripts(),
        ]),
      ),
      scrollBottomInset: 50,
    );
    // acquiring bloc to send it to toolbar
    final notesBloc = BlocProvider.of<NotesBloc>(context);

    final toolbarGradientStartColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .toolbarGradientStartColor;

    final toolbarGradientEndColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .toolbarGradientEndColor;

    final borderColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .titleTextBoxBorderColor;

    return Expanded(
      child: Container(
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassMorphismCover(
              displayShadow: false,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              child: Container(
                child: Toolbar(
                  controller: widget.controller!,
                  notesBloc: notesBloc,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      toolbarGradientStartColor,
                      toolbarGradientEndColor,
                    ],
                    begin: AlignmentDirectional.topCenter,
                    end: AlignmentDirectional.bottomCenter,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GlassPaneForEditor(quillEditor: quillEditor),
            ),
          ],
        ),
      ),
    );
  }
}

class Toolbar extends StatelessWidget {
  final QuillController controller;
  final NotesBloc notesBloc;
  const Toolbar({Key? key, required this.controller, required this.notesBloc})
      : super(key: key);

  // Renders the image picked by imagePicker from local file storage
  // You can also upload the picked image to any server (eg : AWS s3
  // or Firebase) and then return the uploaded image URL.
  Future<String> _onImagePickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    var noteId = notesBloc.state.id;

    final appDocDir = await getApplicationDocumentsDirectory();

    // store the note assets under the folder of its id
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    var filepath = copiedFile.path.toString();

    // we want to record all assets to later delete unused ones
    notesBloc.add(UpdateNote(
        noteAsset: NoteAssetModel(
            noteId: noteId, assetType: "image", assetPath: filepath)));
    return filepath;
  }

  // Renders the video picked by imagePicker from local file storage
  // You can also upload the picked video to any server (eg : AWS s3
  // or Firebase) and then return the uploaded video URL.
  Future<String> _onVideoPickCallback(File file) async {
    var noteId = notesBloc.state.id;

    final appDocDir = await getApplicationDocumentsDirectory();

    // store the note assets under the folder of its id
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');

    var filepath = copiedFile.path.toString();

    // we want to record all assets to later delete unused ones
    notesBloc.add(UpdateNote(
        noteAsset: NoteAssetModel(
            noteId: noteId, assetType: "video", assetPath: filepath)));
    return filepath;
  }

  Future<MediaPickSetting?> _selectMediaPickSetting(
      BuildContext context) async {
    final quillPopupTextColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .quillPopupTextColor;

    final futureResult = showCustomDialog(
      context: context,
      child: SizedBox(
        width: 290,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: Icon(
                Icons.collections,
                color: quillPopupTextColor,
              ),
              label: Text(
                S.current.gallery,
                style: TextStyle(color: quillPopupTextColor),
              ),
              onPressed: () => Navigator.pop(context, MediaPickSetting.Gallery),
            ),
            TextButton.icon(
              icon: Icon(
                Icons.link,
                color: quillPopupTextColor,
              ),
              label: Text(
                S.current.link,
                style: TextStyle(color: quillPopupTextColor),
              ),
              onPressed: () => Navigator.pop(context, MediaPickSetting.Link),
            )
          ],
        ),
      ),
    );

    return futureResult.then((result) => result);
  }

  Future<MediaPickSetting?> _selectCameraPickSetting(
      BuildContext context) async {
    final quillPopupTextColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .quillPopupTextColor;

    final futureResult = showCustomDialog(
      context: context,
      child: SizedBox(
        width: 290,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: Icon(
                Icons.camera,
                color: quillPopupTextColor,
              ),
              label: Text(
                S.current.camera,
                style: TextStyle(color: quillPopupTextColor),
              ),
              onPressed: () => Navigator.pop(context, MediaPickSetting.Camera),
            ),
            TextButton.icon(
              icon: Icon(
                Icons.video_call,
                color: quillPopupTextColor,
              ),
              label: Text(
                S.current.video,
                style: TextStyle(color: quillPopupTextColor),
              ),
              onPressed: () => Navigator.pop(context, MediaPickSetting.Video),
            )
          ],
        ),
      ),
    );

    return futureResult.then((result) => result);
  }

  @override
  Widget build(BuildContext context) {
    QuillIconTheme quillIconTheme = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .toolbarTheme;

    return QuillToolbar.basic(
      controller: controller,
      color: Colors.transparent,
      showSearchButton: true,
      // provide a callback to enable picking images from device.
      // if omit, "image" button only allows adding images from url.
      // same goes for videos.
      embedButtons: FlutterQuillEmbeds.buttons(
        // provide a callback to enable picking images from device.
        // if omit, "image" button only allows adding images from url.
        // same goes for videos.
        onImagePickCallback: _onImagePickCallback,
        onVideoPickCallback: _onVideoPickCallback,
        mediaPickSettingSelector: _selectMediaPickSetting,
        cameraPickSettingSelector: _selectCameraPickSetting,
        showImageButton: true,
        showVideoButton: true,
        showCameraButton: true,
      ),
      // uncomment to provide a custom "pick from" dialog.
      showFontFamily: false,
      showSubscript: true,
      showSuperscript: true,
      showFontSize: false,
      toolbarIconSize: 23,
      toolbarSectionSpacing: 4,
      toolbarIconAlignment: WrapAlignment.center,
      showDividers: true,
      showBoldButton: true,
      showItalicButton: true,
      showSmallButton: false,
      showUnderLineButton: true,
      showStrikeThrough: true,
      showInlineCode: false,
      showColorButton: true,
      showBackgroundColorButton: true,
      showClearFormat: false,
      showAlignmentButtons: false,
      showLeftAlignment: true,
      showCenterAlignment: true,
      showRightAlignment: true,
      showJustifyAlignment: true,
      showHeaderStyle: true,
      showListNumbers: true,
      showListBullets: true,
      showListCheck: true,
      showCodeBlock: true,
      showQuote: true,
      showIndent: false,
      showLink: true,
      showUndo: true,
      showRedo: true,
      multiRowsDisplay: false,
      showDirection: false,
      iconTheme: quillIconTheme,
    );
  }
}

class GlassPaneForEditor extends StatelessWidget {
  const GlassPaneForEditor({
    Key? key,
    required this.quillEditor,
  }) : super(key: key);

  final Widget quillEditor;

  @override
  Widget build(BuildContext context) {
    final richTextGradientStartColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .richTextGradientStartColor;

    final richTextGradientEndColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .richTextGradientEndColor;

    final mainTextColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .mainTextColor;

    final fontCubit = BlocProvider.of<FontCubit>(context);

    return GlassMorphismCover(
      displayShadow: false,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16.0),
        bottomRight: Radius.circular(16.0),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 5),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
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
        child: DefaultTextStyle(
          style: fontCubit.state.currentFontFamily
              .getGoogleFontFamilyTextStyle(mainTextColor),
          child: quillEditor,
        ),
      ),
    );
  }
}
