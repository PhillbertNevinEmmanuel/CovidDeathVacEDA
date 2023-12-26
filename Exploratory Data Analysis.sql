-- Checking the data contained within the tables
-- 1. CovidDeaths Table
SELECT * FROM PortfolioProject.dbo.CovidDeaths ORDER BY 4
-- 2. CovidVaccinations Table
SELECT * FROM PortfolioProject.dbo.CovidVaccinations ORDER BY 4

-- SELECT the data that are going to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2 -- Based of location and date

-- looking at total cases vs total deaths of country X (in this case it's Indonesia because it's my country)
-- shows the likelihood of dying (rough estimate) if you ever contract covid in this country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%ndonesia%'-- using like in case front alphabet is either uppercase or lowercase
AND continent IS NOT NULL
ORDER BY 2 -- sorted by date

-- looking at total cases vs population
-- 1. shows the percentage of population of X that contracted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%ndonesia%'
AND continent IS NOT NULL
ORDER BY 2

-- 2. shows the percentage of population of every country that contracted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- looking at countries with highest infection rate compared to population
-- 1. Based off percentage of populaiton infected
SELECT location, population,
MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- 2. Based off Highest infection count
SELECT location, population,
MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestInfectionCount DESC

-- showing the countries with highest death count per population
SELECT location, population, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- showing highest death count per population of each continent
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- showing global numbers per day date
SELECT date, SUM(new_cases) AS TotalCases,
SUM(CAST(new_deaths AS int)) AS TotalDeaths,
(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS GlobalDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- showing global numbers of total deaths
SELECT SUM(new_cases) AS TotalCases,
SUM(CAST(new_deaths AS int)) AS TotalDeaths,
(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS GlobalDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE CONTINENT IS NOT NULL
ORDER BY 1,2


-- looking at the covid vaccinations data table
SELECT * FROM PortfolioProject.dbo.CovidVaccinations

-- join both tables
SELECT * FROM PortfolioProject.dbo.CovidDeaths AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date

-- looking at total population vs vaccinations received
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3

--creating a partition by to count the sum of people vaccinated per day
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS CountVaccinedPopulation
FROM PortfolioProject.dbo.CovidDeaths AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3

--creating population vs vaccination CTE to get the percentage of vaccinated population from total population

WITH PopulationVsVaccination(continent, location, date, population, new_vaccinations, CountVaccinedPopulation) AS
(SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS CountVaccinedPopulation
--(CountVaccinedPopulation/population)*100
FROM PortfolioProject.dbo.CovidDeaths AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (CountVaccinedPopulation/population)*100 AS VaccinedPopulationPercentage
FROM PopulationVsVaccination

--creating temp table to get the percentage of vaccinated people from total population
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CountVaccinedPopulation numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location,
deaths.date, deaths.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS CountVaccinedPopulation
FROM PortfolioProject.dbo.CovidDeaths AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (CountVaccinedPopulation/population)*100 AS VaccinedPopulationPercentage
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE View PercentPopulationVaccinated AS
SELECT deaths.continent, deaths.location,
deaths.date, deaths.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS CountVaccinedPopulation
FROM PortfolioProject.dbo.CovidDeaths AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3

--Check the view using other query table
SELECT * FROM PercentPopulationVaccinated