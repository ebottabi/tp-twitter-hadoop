/*
 * For user similarity based on items only.
 *  - UDF_JAR_FILE
 *  - TUPLES_WITH_ITEMS_ONLY_FILE
 */

REGISTER $UDF_JAR_FILE;

tweets_with_extracted_entities = LOAD 'tweets_with_entities_extracted' AS (user_id:chararray, mentions:bag {T: tuple(mention:chararray), hashtags:bag {T: tuple(hashtag:chararray), urls:bag {T: tuple(url:chararray), text:chararray) USING PigStorage;

non_merged_tuples_with_items_only = FOREACH tweets_with_extracted_entities GENERATE $0 AS user_id:chararray, BagConcat($1, $2, com.oboturov.ht.pig.InvalidUrlRemover($3)) AS items:bag {T: tuple(mention:chararray)};
--dump non_merged_tuples_with_items_only;
--(@webkarnage,{(@Societysarah),(http://www.realmacsoftware.com/forums/index.php/forums/)})

non_merged_tuples_having_only_some_items = FILTER non_merged_tuples_with_items_only BY NOT IsEmpty(items);
--dump non_merged_tuples_having_only_some_items;

grouped_non_merged_tuples_having_only_some_items = GROUP non_merged_tuples_having_only_some_items BY user_id;
--dump grouped_non_merged_tuples_having_only_some_items;

merged_non_merged_tuples_having_only_some_items = FOREACH grouped_non_merged_tuples_having_only_some_items GENERATE group, com.oboturov.ht.pig.MergeGroupedBags($1);

STORE merged_non_merged_tuples_having_only_some_items INTO 'TUPLES_WITH_ITEMS_ONLY_FILE' USING PigStorage;

tuples_with_items_only_l = LOAD 'TUPLES_WITH_ITEMS_ONLY_FILE' AS (user_id_l:chararray, items_l:bag {T: tuple(item:chararray)});
tuples_with_items_only_r = LOAD 'TUPLES_WITH_ITEMS_ONLY_FILE' AS (user_id_r:chararray, items_r:bag {T: tuple(item:chararray)});

user_user_pairs_with_items_only = CROSS tuples_with_items_only_l, tuples_with_items_only_r;

user_user_pairs_with_items_only_similarity = FOREACH user_user_pairs_with_items_only GENERATE user_id_l, user_id_r, 1.0 - ((double)SIZE(DIFF(items_l, items_r)))/((double)SIZE(BagConcat(items_l, items_r))) AS sim:double;

result_similarity_with_items_only = FILTER user_user_pairs_with_items_only_similarity BY user_id_l != user_id_r AND sim > 0.0;

STORE result_similarity_with_items_only INTO 'similarity_with_items_only_file' USING PigStorage;