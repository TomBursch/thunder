import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lemmy_api_client/v3.dart';

import 'package:thunder/account/bloc/account_bloc.dart' as account_bloc;
import 'package:thunder/community/bloc/community_bloc.dart';
import 'package:thunder/community/pages/create_post_page.dart';
import 'package:thunder/community/widgets/community_drawer.dart';
import 'package:thunder/community/widgets/post_card_list.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/shared/error_message.dart';
import 'package:thunder/shared/sort_picker.dart';
import 'package:thunder/user/bloc/user_bloc.dart' as user_bloc;

class CommunityPage extends StatefulWidget {
  final int? communityId;
  final String? communityName;

  const CommunityPage({super.key, this.communityId, this.communityName});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with AutomaticKeepAliveClientMixin<CommunityPage> {
  @override
  bool get wantKeepAlive => true;

  SortType? sortType;
  IconData? sortTypeIcon;
  String? sortTypeLabel;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isUserLoggedIn = context.read<AuthBloc>().state.isLoggedIn;

    return BlocProvider<CommunityBloc>(
      create: (context) => CommunityBloc(null),
      child: BlocConsumer<CommunityBloc, CommunityState>(
        listenWhen: (previousState, currentState) {
          if (previousState.subscribedType != currentState.subscribedType) {
            context
                .read<account_bloc.AccountBloc>()
                .add(account_bloc.GetAccountInformation());
          }

          if (previousState.sortType != currentState.sortType) {
            setState(() {
              sortType = currentState.sortType;
              final sortTypeItem = allSortTypeItems.firstWhere((sortTypeItem) => sortTypeItem.payload == currentState.sortType);
              sortTypeIcon = sortTypeItem.icon;
              sortTypeLabel = sortTypeItem.label;
            });
          }
          return true;
        },
        listener: (context, state) {
          if (state.status == CommunityStatus.networkFailure) {
            SnackBar snackBar = SnackBar(
              content: Text(state.errorMessage ?? 'No error message available'),
              behavior: SnackBarBehavior.floating,
            );
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) =>
                ScaffoldMessenger.of(context).showSnackBar(snackBar));
          }
        },
        builder: (context, state) {
          return Scaffold(
            floatingActionButton: isUserLoggedIn
                ? FloatingActionButton(
                    onPressed: () {
                      CommunityBloc communityBloc =
                          context.read<CommunityBloc>();

                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: communityBloc,
                          child: CreatePostPage(
                            communityId: state.communityId!,
                            communityInfo: state.communityInfo,
                          ),
                        ),
                      ));
                    },
                  )
                : null,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  final listingType =
                      state.communityId != null ? null : state.listingType;
                  HapticFeedback.mediumImpact();
                  context.read<CommunityBloc>().add(GetCommunityPostsEvent(
                        reset: true,
                        listingType:
                            widget.communityId != null ? null : listingType,
                        communityId:
                            listingType != null ? null : widget.communityId,
                      ));
                },
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      title: Text(getCommunityName(state)),
                      centerTitle: false,
                      toolbarHeight: 70.0,
                      actions: [
                        if ((state.communityId != null ||
                                state.communityName != null) &&
                            isUserLoggedIn)
                          IconButton(
                            icon: Icon(
                              (state.subscribedType ==
                                          SubscribedType.notSubscribed ||
                                      state.subscribedType == null)
                                  ? Icons.library_add_check_outlined
                                  : Icons.library_add_check_rounded,
                              semanticLabel: (state.subscribedType ==
                                          SubscribedType.notSubscribed ||
                                      state.subscribedType == null)
                                  ? 'Subscribe'
                                  : 'Unsubscribe',
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.read<CommunityBloc>().add(
                                    ChangeCommunitySubsciptionStatusEvent(
                                      communityId: state.communityId!,
                                      follow: (state.subscribedType == null)
                                          ? true
                                          : (state.subscribedType ==
                                                  SubscribedType.notSubscribed
                                              ? true
                                              : false),
                                    ),
                                  );
                            },
                          ),
                        IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                semanticLabel: 'Refresh'),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              return context.read<CommunityBloc>().add(
                                  const GetCommunityPostsEvent(reset: true));
                            }),
                        IconButton(
                            icon: Icon(sortTypeIcon, semanticLabel: 'Sort By'),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              showSortBottomSheet(context, state);
                            }),
                        const SizedBox(width: 8.0),
                      ],
                    ),
                    _getBody(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getBody(BuildContext context, CommunityState state) {
    switch (state.status) {
      case CommunityStatus.initial:
        // communityId and communityName are mutually exclusive - only one of the two should be passed in
        context.read<CommunityBloc>().add(GetCommunityPostsEvent(
            reset: true,
            communityId: widget.communityId,
            communityName: widget.communityName));
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      case CommunityStatus.loading:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      case CommunityStatus.refreshing:
      case CommunityStatus.networkFailure:
      case CommunityStatus.success:
        return PostCardList(
          postViews: state.postViews,
          listingType: state.communityId != null ? null : state.listingType,
          communityId: widget.communityId ?? state.communityId,
          communityName: widget.communityName ?? state.communityName,
          hasReachedEnd: state.hasReachedEnd,
          communityInfo: state.communityInfo,
          onScrollEndReached: () => context
              .read<CommunityBloc>()
              .add(GetCommunityPostsEvent(communityId: widget.communityId)),
          onSaveAction: (int postId, bool save) => context
              .read<CommunityBloc>()
              .add(SavePostEvent(postId: postId, save: save)),
          onVoteAction: (int postId, VoteType voteType) => context
              .read<CommunityBloc>()
              .add(VotePostEvent(postId: postId, score: voteType)),
        );

      case CommunityStatus.empty:
      case CommunityStatus.failure:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorMessage(
            message: state.errorMessage,
            action: () => context.read<CommunityBloc>().add(
                GetCommunityPostsEvent(
                    reset: true, communityId: widget.communityId)),
            actionText: 'Refresh Content',
          ),
        );
    }
  }

  void showSortBottomSheet(BuildContext context, CommunityState state) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (builderContext) => SortPicker(
        title: 'Sort Options',
        onSelect: (selected) {
          setState(() {
            sortType = selected.payload;
            sortTypeIcon = selected.icon;
          });

          context.read<CommunityBloc>().add(
                GetCommunityPostsEvent(
                  sortType: selected.payload,
                  reset: true,
                  listingType:
                      state.communityId != null ? null : state.listingType,
                  communityId: widget.communityId ?? state.communityId,
                ),
              );
        },
      ),
    );
  }

  String getCommunityName(CommunityState state) {
    if (state.status == CommunityStatus.initial ||
        state.status == CommunityStatus.loading) {
      return '';
    }

    if (state.communityId != null || state.communityName != null) {
      // return state.postViews?.firstOrNull?.community.name ?? '';
      return '';
    }

    return (state.listingType != null)
        ? (destinations
            .firstWhere(
                (destination) => destination.listingType == state.listingType)
            .label)
        : '';
  }
}
