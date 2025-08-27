-- =====================================================
-- Customer Voice Sentiment Analysis - Complete SQL Queries
-- Dataset: 1,000 customer feedback records
-- Analyst: Chituru Chikwem
-- Project: Voice of the Customer Insight Engine
-- =====================================================

-- Table Structure (for reference)
-- CREATE TABLE customer_feedback (
--     feedback_id VARCHAR(50) PRIMARY KEY,
--     timestamp TIMESTAMP,
--     channel VARCHAR(50),
--     content TEXT,
--     sentiment_score DECIMAL(4,3),
--     sentiment_label VARCHAR(20),
--     topic_cluster INT,
--     confidence DECIMAL(4,3),
--     priority_score DECIMAL(4,3)
-- );

-- =====================================================
-- 1. OVERALL DATASET SUMMARY STATISTICS
-- =====================================================

-- Basic dataset overview
SELECT 
    COUNT(*) as total_feedback,
    COUNT(DISTINCT feedback_id) as unique_feedback,
    MIN(timestamp) as earliest_feedback,
    MAX(timestamp) as latest_feedback,
    COUNT(DISTINCT channel) as channels_count,
    AVG(sentiment_score) as avg_sentiment_score,
    AVG(confidence) as avg_confidence,
    AVG(priority_score) as avg_priority_score
FROM customer_feedback;

-- =====================================================
-- 2. SENTIMENT DISTRIBUTION ANALYSIS (Matches webpage: 45.6% Positive, 31.2% Neutral, 23.2% Negative)
-- =====================================================

SELECT 
    sentiment_label,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_feedback), 1) as percentage,
    AVG(sentiment_score) as avg_score,
    AVG(confidence) as avg_confidence,
    AVG(priority_score) as avg_priority
FROM customer_feedback
GROUP BY sentiment_label
ORDER BY count DESC;

-- Sentiment score distribution
SELECT 
    CASE 
        WHEN sentiment_score >= 0.6 THEN 'Positive (≥0.6)'
        WHEN sentiment_score >= 0.4 THEN 'Neutral (0.4-0.59)'
        ELSE 'Negative (<0.4)'
    END as sentiment_category,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_feedback), 1) as percentage,
    MIN(sentiment_score) as min_score,
    MAX(sentiment_score) as max_score,
    AVG(sentiment_score) as avg_score
FROM customer_feedback
GROUP BY sentiment_category
ORDER BY avg_score DESC;

-- =====================================================
-- 3. CHANNEL PERFORMANCE ANALYSIS (Matches webpage: Social Media 34%, In-App 28%, Support 23%, Email 15%)
-- =====================================================

SELECT 
    channel,
    COUNT(*) as total_feedback,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_feedback), 1) as percentage_of_total,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) as positive_count,
    COUNT(CASE WHEN sentiment_label = 'neutral' THEN 1 END) as neutral_count,
    COUNT(CASE WHEN sentiment_label = 'negative' THEN 1 END) as negative_count,
    ROUND(COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) * 100.0 / COUNT(*), 1) as positive_percentage,
    AVG(confidence) as avg_confidence,
    AVG(priority_score) as avg_priority
FROM customer_feedback
GROUP BY channel
ORDER BY total_feedback DESC;

-- Channel sentiment performance ranking
SELECT 
    channel,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(*) as feedback_count,
    RANK() OVER (ORDER BY AVG(sentiment_score) DESC) as sentiment_rank,
    ROUND(AVG(confidence), 3) as avg_confidence
FROM customer_feedback
GROUP BY channel
ORDER BY avg_sentiment DESC;

-- =====================================================
-- 4. TOPIC CLUSTER ANALYSIS (12 distinct clusters as mentioned in webpage)
-- =====================================================

SELECT 
    topic_cluster,
    COUNT(*) as feedback_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_feedback), 1) as percentage,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) as positive_feedback,
    COUNT(CASE WHEN sentiment_label = 'negative' THEN 1 END) as negative_feedback,
    AVG(confidence) as avg_confidence,
    AVG(priority_score) as avg_priority
FROM customer_feedback
GROUP BY topic_cluster
ORDER BY feedback_count DESC;

-- Top and bottom performing topics by sentiment
(SELECT 
    'TOP_SENTIMENT' as category,
    topic_cluster,
    COUNT(*) as feedback_count,
    ROUND(AVG(sentiment_score), 3) as avg_sentiment,
    ROUND(AVG(priority_score), 3) as avg_priority
FROM customer_feedback
GROUP BY topic_cluster
ORDER BY avg_sentiment DESC
LIMIT 3)
UNION ALL
(SELECT 
    'BOTTOM_SENTIMENT' as category,
    topic_cluster,
    COUNT(*) as feedback_count,
    ROUND(AVG(sentiment_score), 3) as avg_sentiment,
    ROUND(AVG(priority_score), 3) as avg_priority
FROM customer_feedback
GROUP BY topic_cluster
ORDER BY avg_sentiment ASC
LIMIT 3);

-- =====================================================
-- 5. PRIORITY ANALYSIS (Critical 6.7%, High 23.4%, Medium 44.5%, Low 25.4%)
-- =====================================================

SELECT 
    CASE 
        WHEN priority_score >= 0.8 THEN 'Critical'
        WHEN priority_score >= 0.6 THEN 'High'
        WHEN priority_score >= 0.4 THEN 'Medium'
        ELSE 'Low'
    END as priority_level,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_feedback), 1) as percentage,
    AVG(sentiment_score) as avg_sentiment,
    MIN(priority_score) as min_priority,
    MAX(priority_score) as max_priority,
    COUNT(CASE WHEN sentiment_label = 'negative' THEN 1 END) as negative_feedback
FROM customer_feedback
GROUP BY priority_level
ORDER BY avg(priority_score) DESC;

-- High priority negative feedback (Critical issues)
SELECT 
    feedback_id,
    channel,
    timestamp,
    sentiment_score,
    sentiment_label,
    topic_cluster,
    priority_score,
    confidence
FROM customer_feedback
WHERE priority_score >= 0.8 
    AND sentiment_label = 'negative'
ORDER BY priority_score DESC, sentiment_score ASC;

-- =====================================================
-- 6. TEMPORAL ANALYSIS - Monthly Trends
-- =====================================================

SELECT 
    DATE_TRUNC('month', timestamp) as month,
    COUNT(*) as feedback_count,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) as positive_count,
    COUNT(CASE WHEN sentiment_label = 'negative' THEN 1 END) as negative_count,
    ROUND(COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) * 100.0 / COUNT(*), 1) as positive_percentage,
    AVG(priority_score) as avg_priority
FROM customer_feedback
GROUP BY DATE_TRUNC('month', timestamp)
ORDER BY month;

-- Weekly sentiment trends
SELECT 
    DATE_TRUNC('week', timestamp) as week,
    COUNT(*) as feedback_count,
    ROUND(AVG(sentiment_score), 3) as avg_sentiment,
    ROUND(AVG(confidence), 3) as avg_confidence,
    COUNT(DISTINCT channel) as channels_active
FROM customer_feedback
GROUP BY DATE_TRUNC('week', timestamp)
ORDER BY week;

-- =====================================================
-- 7. CONFIDENCE SCORE ANALYSIS
-- =====================================================

SELECT 
    CASE 
        WHEN confidence >= 0.9 THEN 'Very High (≥0.9)'
        WHEN confidence >= 0.8 THEN 'High (0.8-0.89)'
        WHEN confidence >= 0.7 THEN 'Medium (0.7-0.79)'
        ELSE 'Low (<0.7)'
    END as confidence_level,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_feedback), 1) as percentage,
    AVG(sentiment_score) as avg_sentiment,
    AVG(priority_score) as avg_priority
FROM customer_feedback
GROUP BY confidence_level
ORDER BY AVG(confidence) DESC;

-- =====================================================
-- 8. CROSS-CHANNEL SENTIMENT COMPARISON
-- =====================================================

SELECT 
    channel,
    sentiment_label,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY channel), 1) as channel_percentage,
    AVG(sentiment_score) as avg_score,
    AVG(confidence) as avg_confidence
FROM customer_feedback
GROUP BY channel, sentiment_label
ORDER BY channel, sentiment_label;

-- =====================================================
-- 9. TOP INSIGHTS QUERIES (Based on webpage findings)
-- =====================================================

-- High-impact negative feedback by channel
SELECT 
    channel,
    topic_cluster,
    COUNT(*) as negative_count,
    AVG(priority_score) as avg_priority,
    AVG(sentiment_score) as avg_sentiment
FROM customer_feedback
WHERE sentiment_label = 'negative' 
    AND priority_score >= 0.7
GROUP BY channel, topic_cluster
ORDER BY negative_count DESC, avg_priority DESC
LIMIT 10;

-- Best performing topics across channels
SELECT 
    topic_cluster,
    channel,
    COUNT(*) as feedback_count,
    ROUND(AVG(sentiment_score), 3) as avg_sentiment,
    COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) as positive_count
FROM customer_feedback
WHERE sentiment_score >= 0.7
GROUP BY topic_cluster, channel
HAVING COUNT(*) >= 5
ORDER BY avg_sentiment DESC, feedback_count DESC;

-- =====================================================
-- 10. BUSINESS INTELLIGENCE SUMMARY REPORT
-- =====================================================

-- Executive Summary Statistics
WITH summary_stats AS (
    SELECT 
        COUNT(*) as total_feedback,
        ROUND(AVG(sentiment_score), 3) as overall_sentiment,
        COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) as positive_feedback,
        COUNT(CASE WHEN sentiment_label = 'negative' THEN 1 END) as negative_feedback,
        COUNT(CASE WHEN priority_score >= 0.8 THEN 1 END) as critical_issues,
        COUNT(DISTINCT topic_cluster) as topic_clusters,
        COUNT(DISTINCT channel) as channels_used,
        AVG(confidence) as avg_confidence
    FROM customer_feedback
)
SELECT 
    total_feedback,
    overall_sentiment,
    ROUND(positive_feedback * 100.0 / total_feedback, 1) as positive_percentage,
    ROUND(negative_feedback * 100.0 / total_feedback, 1) as negative_percentage,
    ROUND(critical_issues * 100.0 / total_feedback, 1) as critical_percentage,
    topic_clusters,
    channels_used,
    ROUND(avg_confidence, 3) as avg_confidence
FROM summary_stats;

-- Channel performance leaderboard
SELECT 
    ROW_NUMBER() OVER (ORDER BY AVG(sentiment_score) DESC) as rank,
    channel,
    COUNT(*) as total_feedback,
    ROUND(AVG(sentiment_score), 3) as avg_sentiment,
    ROUND(COUNT(CASE WHEN sentiment_label = 'positive' THEN 1 END) * 100.0 / COUNT(*), 1) as positive_rate,
    ROUND(AVG(priority_score), 3) as avg_priority,
    ROUND(AVG(confidence), 3) as avg_confidence
FROM customer_feedback
GROUP BY channel
ORDER BY avg_sentiment DESC;

-- =====================================================
-- 11. VALIDATION QUERIES (To match webpage statistics)
-- =====================================================

-- Verify sentiment distribution matches webpage (45.6% positive, 31.2% neutral, 23.2% negative)
SELECT 
    'Sentiment Distribution Validation' as check_type,
    sentiment_label,
    COUNT(*) as actual_count,
    ROUND(COUNT(*) * 100.0 / 1000, 1) as actual_percentage,
    CASE 
        WHEN sentiment_label = 'positive' THEN 45.6
        WHEN sentiment_label = 'neutral' THEN 31.2
        WHEN sentiment_label = 'negative' THEN 23.2
    END as expected_percentage
FROM customer_feedback
GROUP BY sentiment_label
ORDER BY actual_count DESC;

-- Verify priority distribution matches webpage (6.7% critical, 23.4% high, 44.5% medium, 25.4% low)
SELECT 
    'Priority Distribution Validation' as check_type,
    CASE 
        WHEN priority_score >= 0.8 THEN 'Critical'
        WHEN priority_score >= 0.6 THEN 'High'
        WHEN priority_score >= 0.4 THEN 'Medium'
        ELSE 'Low'
    END as priority_level,
    COUNT(*) as actual_count,
    ROUND(COUNT(*) * 100.0 / 1000, 1) as actual_percentage
FROM customer_feedback
GROUP BY priority_level
ORDER BY AVG(priority_score) DESC;
