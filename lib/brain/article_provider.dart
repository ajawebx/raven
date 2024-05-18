import 'dart:collection';

import 'package:raven/model/article.dart';
import 'package:raven/model/publisher.dart';
import 'package:raven/model/user_subscription.dart';
import 'package:raven/utils/store.dart';
import 'package:worker_manager/worker_manager.dart';

class ArticleProvider {
  int few = 5;
  Set<NewsArticle> stashedArticles = {};
  HashMap<String, int> nextPage = HashMap();

  void reset() {
    stashedArticles = {};
    nextPage = HashMap();
  }

  Future<List<NewsArticle>> loadPage(int page, {String? query}) async {
    List<Future> futures = [];
    List<NewsArticle> newsArticles = [];
    List<NewsArticle> subscriptionArticles = [];
    List<UserSubscription> subscriptions = Store.selectedSubscriptions;
    bool needFresh = false;

    // Load user subscriptions (Publisher+Category)
    for (var subscription in subscriptions) {
      // get publisher for this subscription
      Publisher publisher = publishers[subscription.publisher]!;
      // if there are any articles in stash, un-stash them
      var stashedPublisherArticles = stashedArticles
          .where((e) => e.publisher == publisher.name)
          .toList();
      if (stashedPublisherArticles.isNotEmpty) {
        subscriptionArticles = stashedPublisherArticles.take(few).toList();
        stashedArticles.removeAll(subscriptionArticles);
      }

      // else get fresh articles for this subscription
      else {
        needFresh = true;
        int page_ = nextPage.containsKey(subscription.toString())
            ? nextPage[subscription.toString()]!
            : page;

        if (query != null) {
          futures.add(
            workerManager.execute<Set<NewsArticle>>(
              () {
                return publisher.searchedArticles(
                  searchQuery: query,
                  page: page_,
                );
              },
            ).then(
              (value) {
                if (value.isNotEmpty) {
                  collectPublisherArticles(
                    subscriptionArticles,
                    value,
                    "${value.first.publisher}~${value.first.category}",
                    page,
                  );
                }
              },
            ),
          );
        } else {
          futures.add(
            workerManager.execute<Set<NewsArticle>>(
              () {
                return publisher.categoryArticles(
                  category: subscription.category,
                  page: page_,
                );
              },
            ).then(
              (value) {
                if (value.isNotEmpty) {
                  collectPublisherArticles(
                    subscriptionArticles,
                    value,
                    "${value.first.publisher}~${value.first.category}",
                    page,
                  );
                }
              },
            ),
          );
        }
      }
    }
    if (needFresh) {
      await Future.wait(futures);
    }
    newsArticles.addAll(subscriptionArticles);
    newsArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return newsArticles;
  }

  void collectPublisherArticles(
    List<NewsArticle> subscriptionArticles,
    Set<NewsArticle> articles,
    String subscription,
    int page,
  ) {
    subscriptionArticles.addAll(articles.take(few).toList());
    var stashedArticles_ = articles.skip(few);
    stashedArticles.addAll(stashedArticles_);
    if (stashedArticles_.isNotEmpty) {
      nextPage[subscription] = nextPage.containsKey(subscription)
          ? (nextPage[subscription]! + 1)
          : page + 1;
    }

  }
}
