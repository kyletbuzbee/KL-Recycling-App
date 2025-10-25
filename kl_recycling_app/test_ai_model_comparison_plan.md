# AI Model Comparison Test Plan: KL-Recycling App Weight Prediction

## Executive Summary
This test plan outlines a comprehensive comparison between two AI approaches for scrap metal weight prediction in the KL-Recycling Flutter app:
- **Model A**: Current implementation using Google ML Kit Object Detection + fallback heuristics
- **Model B**: Custom-trained TensorFlow Lite models (scrap_metal_detector + ensemble_model)

The comparison evaluates both **coding quality** (development efficiency, maintainability, performance) and **prediction accuracy** (precision, reliability, real-world effectiveness).

---

## 1. Test Objectives

### Primary Objectives
- Compare end-to-end user experience between both AI implementations
- Measure accuracy improvements in weight prediction for scrap metal items
- Evaluate development velocity and maintainability differences
- Assess mobile performance and resource usage
- Identify the most practical solution for production deployment

### Success Criteria
- Statistical significance in accuracy differences (p < 0.05)
- Minimum 15% accuracy improvement for Model B to justify migration
- Model B code must pass all existing CI checks
- Both models must maintain <50ms inference time on target devices

---

## 2. Test Scope

### In-Scope
- Core weight prediction functionality
- Model loading and initialization
- Camera integration and image preprocessing
- Real-time inference performance
- Offline operation capabilities
- Error handling and fallback mechanisms

### Out-of-Scope
- UI/UX changes (both models use same interface)
- Network-dependent features
- Other app features beyond weight prediction
- Training pipeline comparison (separate evaluation)

---

## 3. Test Environment

### Hardware Specifications
- **Test Devices**:
  - Samsung Galaxy S21 (Android 13)
  - Google Pixel 6 (Android 14)
  - iPhone 13 Pro (iOS 17)
  - iPad Pro 12.9" (iPadOS 17)

- **Development Environment**:
  - Flutter 3.16+
  - Android Studio / Xcode 15+
  - Git workflow with feature branches

### Test Data Specifications
- **Dataset Size**: 500 scrap metal images (100 per material type)
- **Material Types**: Steel, Aluminum, Copper, Brass, Mixed Scrap
- **Image Specifications**: 640x480px minimum, JPEG/PNG format
- **Weight Range**: 0.5-50 lbs (typical scrap loads)
- **Collection**: Real photos from KL Recycling facilities

---

## 4. Test Methodology

### 4.1 Experimental Design
**Within-Subjects Design**: Each test participant uses both models
- Random assignment of model order to reduce learning effects
- Same physical scrap items for consistent comparison
- Counterbalanced presentation to minimize bias

**Sample Size**: 50 participants (25 experienced recyclers, 25 general users)

### 4.2 Coding Quality Assessment (Model Implementation)

#### 4.2.1 Development Velocity Metrics
- Time to complete feature implementation (person-hours)
- Code review feedback density (comments per line)
- Setup time for new developers (minutes to first successful build)

#### 4.2.2 Code Quality Metrics
- Static analysis scores (flutter analyze)
- Unit test coverage (%)
- Cyclomatic complexity per component
- Documentation completeness (README, inline comments)

#### 4.2.3 Performance Metrics
- Compilation time (seconds)
- Binary size increase (MB)
- Memory usage (MB)
- CPU utilization during inference (%)

### 4.3 Accuracy Assessment (Prediction Performance)

#### 4.3.1 Precision Metrics
- **Mean Absolute Error (MAE)**: Average |predicted - actual| weight
- **Mean Absolute Percentage Error (MAPE)**: Average |predicted - actual|/actual
- **Root Mean Square Error (RMSE)**: Square root of mean squared errors

#### 4.3.2 Confidence and Reliability
- Prediction confidence distribution (calibration curves)
- Within-range accuracy (predictions within ±5%, ±10%, ±15%)
- Material-specific accuracy breakdown
- Edge case handling (very small/large items, poor lighting)

#### 4.3.3 User Experience Metrics
- Time to complete weight estimation workflow (seconds)
- Successful prediction rate (% of attempts)
- Error recovery effectiveness
- Subjective satisfaction scores (Likert scale 1-5)

### 4.4 Statistical Analysis Plan
- **T-tests** for comparing means between models
- **ANOVA** for multi-material comparison
- **Chi-square tests** for categorical outcomes
- **Regression analysis** for learning effects
- **Confidence intervals** (95%) for all key metrics

---

## 5. Test Cases and Scenarios

### 5.1 Coding Quality Test Cases

#### TC-CQ-001: Development Setup
- Create fresh checkout of both model implementations
- Measure time to configure development environment
- Record number of configuration issues encountered

#### TC-CQ-002: Feature Implementation
- Implement identical feature (e.g., weight adjustment UI)
- Measure lines of code added
- Evaluate API surface complexity

#### TC-CQ-003: Code Review Process
- Conduct blinded code review sessions
- Score maintainability on 5-point scale
- Identify architectural concerns

#### TC-CQ-004: Performance Profiling
- Profile memory usage during model loading
- Measure inference time across device types
- Analyze power consumption patterns

### 5.2 Accuracy Test Cases

#### TC-AC-001: Precision Benchmark
- Test 20 steel items of known weights (5-50 lbs)
- Compare predictions vs ground truth
- Calculate MAE, MAPE, RMSE for both models

#### TC-AC-002: Material Type Accuracy
- Test 10 items per material type
- Analyze performance by material category
- Identify material-specific performance differences

#### TC-AC-003: Image Quality Variation
- Test with: well-lit, poorly-lit, blurry, angled photos
- Measure robustness to image quality degradation
- Evaluate fallback mechanism effectiveness

#### TC-AC-004: Size Range Performance
- Items from 1 lb to 500 lbs
- Analyze accuracy scaling with item size
- Test edge cases (very small/large items)

#### TC-AC-005: Real-World User Testing
- Participants weigh 15 scrap items with each model
- Record actual weights (ground truth) for comparison
- Collect subjective usability feedback

---

## 6. Test Execution Plan

### Phase 1: Preparation (Week 1-2)
- Set up feature branches for both model implementations
- Implement missing components in each approach
- Create comprehensive test datasets
- Develop automated measurement tools

### Phase 2: Coding Quality Evaluation (Week 3)
- Execute coding quality test cases (TC-CQ%)
- Collect development metrics and code review data
- Complete static analysis and performance profiling

### Phase 3: Accuracy Testing (Week 4)
- Execute accuracy test cases (TC-AC%)
- Collect precision metrics and user feedback
- Validate statistical significance of results

### Phase 4: Analysis and Reporting (Week 5)
- Statistical analysis of collected data
- Generate comprehensive test report
- Create recommendations for model selection

---

## 7. Risk Analysis and Mitigation

### Technical Risks
- **Model Loading Failures**: Implement robust error handling and fallbacks
- **Performance Degradation**: Monitor and document mobile performance impacts
- **Device Compatibility**: Test on wide range of Android/iOS devices

### Experimental Risks
- **Learning Effects**: Counterbalancing and randomization in test design
- **Measurement Bias**: Automated collection and blinded analysis
- **Sample Bias**: Diverse participant recruitment (novice vs expert users)

---

## 8. Success Metrics Dashboard

### Coding Quality KPIs
- Lines of code: <500 total implementation
- Flutter analyze score: >95/100
- Unit test coverage: >85%
- Compilation time: <3 minutes

### Accuracy KPIs
- MAE: <10% of average item weight
- MAPE: <15% for items >5 lbs
- Within 10% accuracy: >75% of predictions
- User satisfaction: >4.0/5.0 average rating

---

## 9. Deliverables

### Documentation
- Test Plan Document (this file)
- Test Execution Logs and Raw Data
- Statistical Analysis Report
- Model Comparison Dashboard (optional Flutter app)

### Code
- Feature branches for both implementations
- Automated measurement and testing tools
- CI/CD pipeline updates for model validation

### Recommendations
- Preferred model selection with justification
- Migration plan (if switching models)
- Future improvement roadmap
- Implementation timeline and resource requirements

---

## 10. Timeline and Milestones

| Phase | Duration | Deliverables | Stakeholders |
|-------|----------|--------------|--------------|
| Preparation | 2 weeks | Feature branches, test data | Dev Team |
| Coding Eval | 1 week | Performance benchmarks, code review | Code Reviewers |
| Accuracy Test | 1 week | Precision metrics, user feedback | Product, QA |
| Analysis | 1 week | Final report, recommendations | Leadership |

---

## 11. Assumptions and Constraints

### Assumptions
- Access to GPU training infrastructure for custom models
- Availability of ground truth weight measurements
- Stable Flutter development environment
- Representative sample of target users

### Constraints
- Budget limitations on extensive user testing
- Time constraints for complete model retraining
- Limited access to proprietary training data
- Mobile performance requirements (<50ms inference)

---

## 12. Approval and Sign-off

### Test Plan Approval
- **Developer Sign-off**: Implementation feasibility confirmed
- **Product Sign-off**: Business objectives aligned
- **QA Sign-off**: Test methodology validated

### Final Report Acceptance
- **Technical Review**: Code quality assessment completed
- **Business Review**: ROI analysis and recommendations reviewed
- **Executive Approval**: Go/no-go decision for model migration

---

**Test Plan Version**: 1.0
**Last Updated**: October 23, 2025
**Document Owner**: AI Testing Team
