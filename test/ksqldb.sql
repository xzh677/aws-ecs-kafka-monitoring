
DROP STREAM user_stream;

CREATE STREAM user_stream (
    registertime BIGINT,
    userid VARCHAR KEY,
    regionid VARCHAR,
    gender VARCHAR
) WITH (
    kafka_topic='sample_data',
    value_format='JSON_SR'
);


select * from  USER_STREAM  EMIT CHANGES;


CREATE TABLE user_counts WITH (
    kafka_topic='user_counts',
    key_format='JSON_SR',
    value_format='JSON_SR'
) AS
SELECT userid,
       COUNT(*) AS count
FROM user_stream
GROUP BY userid
EMIT CHANGES;

SELECT * FROM USER_COUNTS;