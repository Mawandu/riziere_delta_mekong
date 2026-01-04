# Rice Field Salinity Management System
## Agent-Based Model for Climate Adaptation in the Mekong Delta

[![GAMA Platform](https://img.shields.io/badge/GAMA-1.9.2-green.svg)](https://gama-platform.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Active](https://img.shields.io/badge/Status-Active-success.svg)]()

> An intelligent multi-agent simulation system modeling farmer decision-making and collective water management in response to saltwater intrusion in the Mekong Delta, Vietnam.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Model Description](#model-description)
- [Results & Outputs](#results--outputs)
- [Future Development](#future-development)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Overview

### Context

The Mekong Delta faces increasing **saltwater intrusion** due to:
- Climate change and sea level rise
- Prolonged droughts during dry seasons
- Upstream dam construction reducing freshwater flow

This threatens rice production, the main livelihood for millions of farmers.

### Purpose

This project simulates:
- **Farmer adaptation strategies** to salinity stress
- **Collective irrigation management** through canal systems
- **Learning and knowledge sharing** among farming communities
- **Environmental monitoring systems** for early warning

### Goals

1. Understand emergence of collective behaviors in crisis situations
2. Test effectiveness of different farmer strategies (prudent, optimistic, follower)
3. Evaluate impact of monitoring systems and agricultural advisors
4. Support policy-making for sustainable water management

---

## Features

### Multi-Agent System

- **Farmers (20 agents)**: Cognitive agents with different strategies
  - Make irrigation decisions based on salinity levels
  - Learn from experience and adjust thresholds
  - Share information with neighbors
  - Manage capital and resources

- **Rice Paddies (100 agents)**: Dynamic environmental entities
  - Track salinity levels (0-100 g/L)
  - Monitor water levels and crop growth stages
  - Calculate yields based on environmental conditions
  - Visual color gradient (green → yellow → orange)

- **Canals (5 agents)**: Infrastructure for water management
  - Connect to sea with varying distances
  - Propagate saltwater during high tides
  - Sluice gates controlled by collective farmer decisions

- **Sensors (3 agents)**: Monitoring network
  - Measure salinity in designated zones
  - Send alerts when critical thresholds exceeded
  - Provide real-time data to farmers

- **Agricultural Advisor (1 agent)**: Expert support system
  - Train novice farmers
  - Recommend best practices
  - Facilitate collective decision-making

### Environmental Dynamics

- **Seasonal cycles** (120 days): Dry season → Rainy season → Harvest
- **Tidal dynamics**: Lunar cycle affecting saltwater intrusion
- **Rainfall patterns**: Variable precipitation affecting dilution
- **Evaporation**: Temperature-dependent water loss
- **Rice growth**: Stage-based development (0-120 days)

### Visualization & Monitoring

Real-time displays:
- **2D spatial map** with color-coded salinity levels
- **Salinity evolution chart** tracking average delta salinity
- **Rice production graph** showing total yield over time
- **Degraded paddies counter** monitoring affected areas
- **Environmental conditions** dashboard (tide, season, rainfall)

9 live monitors tracking:
- Simulation day, current season
- Average salinity, degraded paddies percentage
- Total rice yield, tide intensity
- Rainfall, temperature

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GAMA Simulation Platform                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐      ┌──────────────────────────────┐    │
│  │  Environment  │      │     Multi-Agent System       │    │
│  │               │      │                              │    │
│  │ • Grid System │◄────►│ • Farmers (cognitive)        │    │
│  │ • Salinity    │      │ • Paddies (reactive)         │    │
│  │ • Tides       │      │ • Canals (infrastructure)    │    │
│  │ • Seasons     │      │ • Sensors (monitoring)       │    │
│  └───────────────┘      │ • Advisor (expert)           │    │
│         ▲               └──────────────────────────────┘    │
│         │                              │                    │
│         │                              ▼                    │
│  ┌──────┴──────────────────────────────────────────-┐       │
│  │            Decision-Making Engine                │       │
│  │  • Strategy Selection (Prudent/Optimist/Follower)│       │
│  │  • Learning & Adaptation                         │       │
│  │  • Collective Sluice Management                  │       │
│  └──────────────────────────────────────────────────┘       │
│                              │                              │
│                              ▼                              │
│  ┌───────────────────────────────────────────────┐          │
│  │        Visualization & Analysis               │          │
│  │  • Real-time Maps  • Charts  • Monitors       │          │
│  └───────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### Agent Interaction Flow

```
Sensors ──[measure]──► Farmers ──[irrigation]──► Paddies
   │                      │                         │
   │                      │                         │
   ▼                      ▼                         ▼
Advisor ──[training]──► Neighbors ◄──[share]──  Canals
                           │
                           ▼
                    [collective vote]
                           │
                           ▼
                    Sluice Control
```

---

## Installation

### Prerequisites

- **GAMA Platform** 1.8.2 or higher ([Download](https://gama-platform.org/download))
- Java 11+ (included with GAMA)
- 4GB RAM minimum (8GB recommended)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Mawandu/riziere_delta_mekong.git
   cd riziere_delta_mekong
   ```

2. **Open in GAMA**
   - Launch GAMA Platform
   - File → Import → Existing Projects into Workspace
   - Select the cloned directory
   - Click Finish

3. **Run the simulation**
   - Open `riziere_main.gaml`
   - Click the green ▶ button
   - Select experiment: `Simulation_Rizieres`

---

## Usage

### Running a Basic Simulation

1. **Launch**: Click ▶ on `riziere_main.gaml`
2. **Configure** (optional): Adjust parameters in the sidebar
   - Number of farmers (10-50)
   - Number of paddies (50-200)
   - Critical salinity threshold (2.0-8.0 g/L)
   - Base evaporation rate (2.0-10.0 mm/day)
3. **Start**: Press Play ⏯
4. **Monitor**: Watch real-time evolution on displays

### Exploring Different Scenarios

**Scenario 1: Extreme Drought**
```
- Set evaporation_base = 10.0
- Reduce rainfall
- Observe farmer adaptation
```

**Scenario 2: Saltwater Invasion**
```
- Increase tide intensity
- Place canals closer to sea
- Monitor collective sluice decisions
```

**Scenario 3: Learning Impact**
```
- Compare simulations with/without advisor
- Track farmer knowledge evolution
- Measure yield improvements
```

### Exporting Data

Add this to the `global` block for CSV export:

```gaml
reflex save_data when: every(10 #cycles) {
    save [
        jour_simulation,
        salinite_moyenne,
        rendement_total,
        nb_parcelles_degradees
    ] to: "results.csv" type: csv rewrite: false;
}
```

---

## Model Description

### Conceptual Framework

Based on **Voyelles approach** (Demazeau, 1997):
- **A**gents: Farmers, paddies, canals, sensors, advisor
- **E**nvironment: Delta grid with salinity and water dynamics
- **I**nteractions: Irrigation, information sharing, collective voting
- **O**rganization: Neighborhood networks, advisor-farmer hierarchy

### Key Algorithms

**1. Farmer Decision-Making**
```
FOR each paddy owned:
    IF (salinity > threshold) OR (water_level < minimum):
        IF has_pump AND capital > irrigation_cost:
            IRRIGATE(paddy)
            UPDATE knowledge
```

**2. Salinity Propagation**
```
salinity += (tide_intensity / distance_to_sea) * 0.1
salinity += evaporation * 0.05
salinity *= (1 - rainfall / 200)
salinity = CLAMP(salinity, 0, 100)
```

**3. Learning Mechanism**
```
IF yield < expected:
    ANALYZE past_decisions
    ADJUST salinity_threshold -= 0.5
    INCREASE knowledge += 0.05
```

**4. Collective Sluice Management**
```
votes_close = COUNT(farmers WHERE avg_salinity > 3.0)
IF votes_close > total_farmers / 2:
    sluice_state = CLOSED
ELSE:
    sluice_state = OPEN
```

### Parameters

| Parameter                 | Default |  Range  |    Description             |
|---------------------------|---------|---------|----------------------------|
| `nb_agriculteurs`         |    20   | 10-50   |    Number of farmer agents |
| `nb_parcelles`            |   100   | 50-200  |     Number of rice paddies |
| `nb_canaux`               |    5    |   3-10  | Number of irrigation canals|
| `seuil_salinite_critique` |   4.0   | 2.0-8.0 |    Critical salinity (g/L) |
| `evaporation_base`        |   5.0   | 2.0-10.0|  Daily evaporation (mm)    |
| `cycle_saison`            |   120   | 90-180  | Seasonal cycle (days)      |

### Validation

Model validation based on:
- **Literature**: Salinity thresholds from agronomic studies
- **Field data**: Tidal patterns from Mekong Delta observations
- **Expert knowledge**: Farmer strategies from interviews
- **Stylized facts**: Qualitative behavior matching real systems

---

## Results & Outputs

### Sample Outputs

**Salinity Evolution**
- Seasonal oscillations matching dry/rainy patterns
- Spatial gradient from coast to inland
- Critical threshold exceedance events

**Farmer Adaptation**
- Prudent farmers: Low risk, stable yields
- Optimistic farmers: Higher risk, variable yields
- Followers: Convergent behavior, intermediate results

**Collective Management**
- Emergence of coordinated sluice control
- Trade-offs between water access and salinity
- Learning accelerated by advisor presence

### Emergent Phenomena

1. **Self-organization**: Farmers spontaneously coordinate without central authority
2. **Knowledge diffusion**: Successful strategies spread through networks
3. **Adaptive resilience**: System recovers from salinity shocks through learning
4. **Spatial clustering**: Similar strategies concentrate in neighborhoods

---

## Future Development

### Planned Features

- [ ] **Economic module**: Rice market prices, investments, loans
- [ ] **Policy tools**: Subsidies, water quotas, protected zones
- [ ] **GIS integration**: Real Mekong Delta map import
- [ ] **Machine Learning**: Predictive models for salinity forecasting
- [ ] **Participatory mode**: Interface for real farmers to test strategies
- [ ] **3D visualization**: Immersive VR environment
- [ ] **Multi-crop system**: Rice, shrimp, fish farming
- [ ] **Climate scenarios**: El Niño, sea level rise projections

### Research Extensions

1. **Sensitivity analysis**: Systematic parameter space exploration
2. **Optimization**: Multi-objective search for best management strategies
3. **Calibration**: Fit to real yield and salinity time series
4. **Validation**: Field experiments comparing model predictions

---

## Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Coding Standards

- Follow GAMA syntax conventions
- Comment complex algorithms in English
- Add documentation for new parameters
- Test thoroughly before submitting

### Reporting Issues

Use GitHub Issues to report:
- Bugs: Unexpected behavior or crashes
- Feature requests: New capabilities
- Documentation: Unclear explanations
- Questions: Usage or interpretation

---

## Acknowledgments

### Inspiration

- **Ferber, J. (1995)**: *Les Systèmes Multi-Agents* - Foundational SMA concepts
- **Epstein & Axtell (1996)**: *Growing Artificial Societies* - Agent-based modeling methodology


*Last updated: January 2026*