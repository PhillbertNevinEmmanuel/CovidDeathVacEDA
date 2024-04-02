-- 1.

SELECT SUM(new_cases) total_cases, SUM(CAST(new_deaths AS int)) total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 death_percentage
FROM CovidDeathVaccinationsProject.dbo.CovidDeaths
WHERE continent is not null 
ORDER BY total_cases, total_deaths

-- 2.

SELECT location, SUM(CAST(new_deaths AS int)) total_death_count
FROM CovidDeathVaccinationsProject.dbo.CovidDeaths
WHERE continent IS NULL
AND location NOT IN('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC

-- 3.

SELECT location, population, MAX(total_cases) highest_infection_count, MAX((total_cases/population))*100 percent_population_infected
FROM CovidDeathVaccinationsProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- 4.
SELECT location, population, date, MAX(total_cases) highest_infection_count, MAX(total_cases/population)*100 percent_population_infected
FROM CovidDeathVaccinationsProject.dbo.CovidDeaths
GROUP BY location, population, date
ORDER BY percent_population_infected DESC

