-- Exploratory data analysis

select * from layoffs_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select * from layoffs_staging2
where percentage_laid_off = 1;

select company, sum(total_laid_off) sum_of_layoffs
from layoffs_staging2
group by company
order by 2 desc;

with sum_of_total_layoffs as (
select company, sum(total_laid_off) sum_of_layoffs
from layoffs_staging2
group by company
order by 2 desc)
select sum(sum_of_layoffs)
from sum_of_total_layoffs;

select min(`date`), max(`date`)
from layoffs_staging2;

select year(`date`), sum(total_laid_off) sum_of_layoffs
from layoffs_staging2
group by year(`date`)
order by 2 desc;

select substring(`date`,1, 7) as `month`, sum(total_laid_off)
from layoffs_staging2
where substring(`date`,1, 7) is not null
group by `month`
order by 1 asc;

-- rolling total
with rolling_total as (
select DATE_FORMAT(`date`, '%Y-%m') as `month`, sum(total_laid_off) tot_off
from layoffs_staging2
where DATE_FORMAT(`date`, '%Y-%m') is not null
group by `month`
order by 1 asc)
select `month`, tot_off,
 sum(tot_off) over(order by `month`) rol_total # over with order by accumulates the sum
from rolling_total;

SELECT 
    company, 
    industry, 
    `date`, 
    total_laid_off,
    -- Running total of layoffs, resetting for each industry!
    SUM(total_laid_off) OVER(PARTITION BY industry ORDER BY `date`) AS industry_running_total
FROM layoffs_staging2;

with layoff_percentage as (
select company, industry, total_laid_off, 
sum(total_laid_off) over(partition by industry) sum_layoff
from layoffs_staging2)
select * , round((total_laid_off * 100) / sum_layoff, 2) as percentage
 from layoff_percentage;
 
 SELECT 
    company, 
    industry, 
    total_laid_off,
    SUM(total_laid_off) OVER(PARTITION BY industry) AS sum_layoff,
    ROUND((total_laid_off * 100.0) / SUM(total_laid_off) OVER(PARTITION BY industry), 2) AS percentage
FROM layoffs_staging2
WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL;

with company_year as(
select company, year(`date`) `year`, sum(total_laid_off) sum_layoff
from layoffs_staging2
group by company, `year`)
select *, dense_rank() over(partition by `year` order by sum_layoff desc)
from company_year;