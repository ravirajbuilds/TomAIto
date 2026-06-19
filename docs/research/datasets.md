# OrchardEye — Public Dataset Catalog for Plant-Disease CV & Fruit-Quality Spectroscopy

*Compiled 2026-06-19. Crops of interest: tomato (prototype), apple, cherry; plus NIR/spectral fruit-quality data. Figures are cross-checked across ≥2 independent sources where possible; anything not confirmable from a primary/authoritative source is marked **[unverified]**. Many publisher pages (ScienceDirect, arXiv, Kaggle, Mendeley, PMC) returned HTTP 403 to automated fetch, so several numbers rest on corroborating search snippets + data-paper text rather than a single primary-page load.*

---

## 1. Your provided dataset — "Tomato Disease Dataset" (Mendeley `c2x8rynybg`)

**Characterized in detail (this is the dataset the user supplied):**

| Field | Value |
|---|---|
| **Title (dataset)** | *Tomato Disease Dataset* (Mendeley Data) |
| **Associated data paper** | "A labeled image dataset of common tomato diseases for classification and object detection," *Data in Brief*, vol. 63, 2025 |
| **Authors** | Yongbo Liu, Yuhang Zhu, Liang Hu, Yao Huo, Wenbo Gao, Rongping Hu, Peng He |
| **Year** | 2025 (images collected 2024) |
| **DOIs** | Dataset: `10.17632/c2x8rynybg.1` · Article: `10.1016/j.dib.2025.112032` |
| **Exact image count** | **1,026 images** (≈2.78 GB of images; ~3.14 GB total package). *Note: this corrects the "~1206" in the brief — the verified count is **1,026**, not 1,206.* |
| **Class breakdown** | Viral disease **417** · Bacterial wilt **527** · Gray mold **82** (= 1,026) |
| **Crop** | Tomato only |
| **Annotation type** | **Bounding boxes** — manually annotated with **LabelImg** under plant-pathology expert guidance. Labeled regions span **leaves, fruits, and stems** (3 organ types). Format is LabelImg's standard **Pascal VOC XML** (commonly convertible to YOLO); exact on-disk format string **[unverified]** beyond "LabelImg." |
| **Resolution** | "High-resolution" images shot from multiple angles/distances (multi-scale); exact pixel dimensions **[unverified]** |
| **Conditions** | **Real-world greenhouse** (protected agriculture) — a modern agricultural park, Sichuan Province, China. Not lab/uniform-background; not open field. |
| **License** | **CC BY-NC** (non-commercial) — reported consistently across sources; verify the exact variant (3.0 vs 4.0) on the Mendeley record before commercial use |
| **URL** | https://data.mendeley.com/datasets/c2x8rynybg/1 |

**Usefulness for OrchardEye:** This is a strong *object-detection* fit for the tomato prototype because (a) it is **boxed**, not just image-level labeled, and (b) it is **greenhouse/real-world**, so it transfers to deployment far better than lab data. Caveats: it is **small (1,026 images)**, **only 3 diseases** (and these are mostly whole-plant conditions — viral/bacterial wilt/gray mold — rather than the foliar-spot classes in PlantVillage), **gray mold is severely under-represented (82)**, and the **CC BY-NC** license blocks commercial deployment. Best used to *fine-tune* a detector for greenhouse tomato after pretraining on a larger leaf set.

---

## 2. Master catalog table

| Dataset | Year | # Images | Crops / Classes | Annotation | Conditions | License | URL |
|---|---|---|---|---|---|---|---|
| **Tomato Disease Dataset** (Mendeley c2x8rynybg) | 2025 | **1,026** | Tomato; 3 (viral, bacterial wilt, gray mold) | Bounding boxes (LabelImg/VOC); leaves+fruits+stems | Greenhouse (real-world) | CC BY-NC | [link](https://data.mendeley.com/datasets/c2x8rynybg/1) |
| **PlantVillage** | 2015–16 | **54,306** | 14 crops / **38 classes**. Tomato **10**, Apple **4**, Cherry **2** | Image-level labels only | **Lab** (uniform background) | CC0 on Mendeley mirror; not stated on GitHub → **[unverified/varies]** | [GitHub](https://github.com/spMohanty/PlantVillage-Dataset) |
| **PlantDoc** | 2020 | **2,598** | 13 species / **27 classes** (incl. tomato, apple, cherry) | **Bounding boxes** (8,851 boxes) + cropped-classification version | **Field** (in-the-wild) | CC BY 4.0 | [GitHub](https://github.com/pratikkayal/PlantDoc-Dataset) |
| **Plant Pathology 2020 (FGVC7)** | 2020 | 3,651 (paper) / **3,642** released (1,821 train + 1,821 test) | **Apple**; 4 (healthy, scab, cedar rust, multiple/"complex") | Image-level labels (single-label) | **Field** orchard (Cornell AgriTech, NY) | Kaggle comp. data; string **[unverified]** | [Kaggle](https://www.kaggle.com/c/plant-pathology-2020-fgvc7) |
| **Plant Pathology 2021 (FGVC8)** | 2021 | **18,632** | **Apple**; 6 (scab, rust, powdery mildew, frog-eye leaf spot, complex, healthy) | Image-level, **multi-label** | **Field** orchard | Kaggle comp. data; string **[unverified]** | [Kaggle](https://www.kaggle.com/c/plant-pathology-2021-fgvc8) |
| **Tomato-Village** | 2023 | **14,368** (multilabel subset 4,529) | **Tomato**; multilabel subset 7 classes (incl. nutrient deficiencies, leaf miner) | Classification + **object-detection** subsets (boxes) | **Field** (Rajasthan, India) | **[unverified]** | [Springer](https://link.springer.com/article/10.1007/s00530-023-01158-y) / [GitHub](https://github.com/mamta-joshi-gehlot/Tomato-Village) |
| **Taiwan Tomato Leaves** | — | **622** | Tomato; 6 (bacterial spot, black mold, gray spot, late blight, powdery mildew, healthy) | Image-level labels (resized 227×227) | Mixed (single+multi-leaf, varied bg) | **[unverified]** | [GTS](https://gts.ai/dataset-download/taiwan-tomato-leaves-dataset/) |
| **Tomato — "Multiple Sources"** (Kaggle, cookiefinder) | 2022 | ~25,851 train (total ~32k **[unverified]**) | Tomato; 11 (10 disease + healthy) | Image-level labels | Mixed/aggregated (partly PlantVillage) | **[unverified]** | [Kaggle](https://www.kaggle.com/datasets/cookiefinder/tomato-disease-multiple-sources) |
| **Tomato Leaves** (Kaggle, ashishmotwani) | — | >20,000 | Tomato; 11 | Image-level labels | **Lab + field mixed** | **[unverified]** | [Kaggle](https://www.kaggle.com/datasets/ashishmotwani/tomato) |
| **Cherry-leaves** (Kaggle, Code Institute) | — | **4,208** | **Cherry**; 2 (healthy, powdery mildew) | Image-level labels (binary) | **Lab** (neutral background) | **[unverified]** | [Kaggle](https://www.kaggle.com/datasets/codeinstitute/cherry-leaves) |
| **DeepHS-Fruit** (Varga et al.) | 2021 | **~5,000** recordings **[exact unverified]** | Avocado, kiwi, mango, kaki, papaya; ripeness stages (+ firmness, sugar) | Hyperspectral cubes + destructive ground-truth labels | Lab (Specim FX10, Corning microHSI 410, INNO-SPEC RedEye) | Not stated **[unverified]** | [GitHub](https://github.com/cogsys-tuebingen/deephs_fruit) |
| **Multispectral apples — ripeness/Brix/variety** (Mendeley) | 2025 | **32,463** (Brix-labeled subset **1,620**) | **Apple**; Brix 10–15%, ripeness (18-day), 5–6 varieties | 8-band multispectral images; Brix via handheld refractometer | **Low-cost custom 8-band imaging chamber** | Mendeley default CC BY 4.0 → **[unverified]** | [Mendeley](https://data.mendeley.com/datasets/y5h6v8w6ms/2) |
| **Mango DMC + NIR spectra** (Anderson, Walsh, Subedi) | 2020 | thousands (~11k spectra **[unverified]**) | Mango; dry-matter content (maturity proxy, not Brix) | NIR absorbance spectra, **309–1149 nm** | Lab/handheld NIR (Felix F-750-class **[unverified]**) | **CC BY 4.0** | [Mendeley](https://data.mendeley.com/datasets/46htwnp833/4) / [GitHub mirror](https://github.com/spectral-datasets/mango-dmc) |

---

## 3. Per-dataset notes for OrchardEye

**PlantVillage** — The backbone for pretraining. Confirmed: **38 classes / 14 crops / 54,306 images**. **Tomato = 10 classes** (bacterial spot, early/late blight, leaf mold, Septoria, spider mites, target spot, yellow leaf curl virus, mosaic virus, healthy). **Apple = 4 classes** (`Apple___Apple_scab`, `Apple___Black_rot`, `Apple___Cedar_apple_rust`, `Apple___healthy`). **Cherry = 2 classes, CONFIRMED present**: `Cherry_(including_sour)___Powdery_mildew` and `Cherry_(including_sour)___healthy` (powdery mildew = *Podosphaera clandestina*), ~1,900 images combined (per-class split ~1,052/~854 is **[unverified]**). The fatal caveat: it is **lab imagery on uniform backgrounds**, so models overfit to background and transfer poorly to field/greenhouse. Use it to pretrain, never as your only data. License is **CC0 on the Mendeley mirror** but unstated on the GitHub repo — treat as **varies/[unverified]** and pin it down before commercial use.

**PlantDoc** — The single best cross-crop **field** complement: it covers **tomato, apple, AND cherry** in real conditions with **bounding boxes**, under a clean **CC BY 4.0** license. Small (2,598 images), but ideal for domain-adapting a detector off PlantVillage pretraining. (Author surname correction: the team is Singh, Jain, Jain, Kayal, **Kumawat**, Batra — not "Kumar.")

**Apple — Plant Pathology 2020/2021 (FGVC)** — The strongest **apple-specific, field-condition** resource. 2020 is 4-class single-label (~3.6k); **2021 scales to 18,632 multi-label images** and adds powdery mildew + frog-eye leaf spot. Both are **image-level only (no boxes)** and image-classification oriented. Excellent for an apple foliar-disease classifier; pair with a detector trained elsewhere if you need localization. License strings are **[unverified]** (Kaggle pages blocked) — confirm Kaggle competition terms before redistribution.

**Tomato — beyond PlantVillage** — For the prototype, the most deployment-relevant is **Tomato-Village** (14,368 images, **field**, India; has an **object-detection** subset and adds field-only categories like leaf miner and nutrient deficiencies). The large Kaggle sets (cookiefinder ~25k, ashishmotwani >20k) give volume and 11 classes but are partly PlantVillage-derived and have **[unverified] licenses**. Roboflow Universe has many boxed field tomato sets of varying quality. **Recommendation: prototype on PlantVillage-tomato (pretrain) → fine-tune on your Mendeley greenhouse set + Tomato-Village for field/greenhouse realism.**

**Cherry — the honest gap** — Cherry is **genuinely scarce**. There are effectively **two overlapping public sources, both lab-style and both powdery-mildew-only**: (1) **PlantVillage cherry** (~1,900 lab images, 2 classes) and (2) the **Kaggle Code-Institute "cherry-leaves" set** (4,208 leaves, **binary** healthy vs powdery mildew — note this is 2 classes, not the "4 classes" some course materials imply). There are **no public field/orchard cherry datasets, no cherry-fruit disease datasets, and no other cherry diseases** (no brown rot, bacterial canker, leaf spot). This is dramatically poorer than tomato/apple. **Plan accordingly:** expect to collect your own cherry field/fruit imagery, lean on transfer learning, and consider few-shot/augmentation strategies for cherry from day one.

**NIR / spectral fruit quality — the second honest gap** — Public spectral fruit-quality data is dominated by **expensive lab instruments**: **DeepHS-Fruit** (hyperspectral, Specim FX10 / Corning microHSI / INNO-SPEC; ~5,000 recordings; avocado/kiwi/mango/kaki/papaya — **no apple, no cherry, no tomato**) and the **Anderson mango DMC NIR** set (309–1149 nm, CC BY 4.0, but DMC not Brix, and mango). The closest to apple-Brix is a **2025 Mendeley multispectral-apple** set (32,463 images, **1,620 Brix-labeled**) built with a **low-cost custom 8-band imaging chamber** — promising, but it's **multispectral imaging, not point spectroscopy**, and not your sensor. **Critically: there is no large public dataset captured with the AS7265x (or any comparable cheap ~410–940 nm point sensor) for fruit Brix/ripeness.** AS7265x-based studies (e.g., "SweetFruit," portable tomato-ripeness work) consistently **keep their data private**. If OrchardEye standardizes on the AS7265x, you will almost certainly **need to build your own spectral calibration dataset** (fruit + refractometer Brix ground-truth); public data can at best inform method choice, not be dropped in directly.

---

## 4. Recommended starting point

1. **Tomato prototype:** pretrain on **PlantVillage-tomato** (volume, clean labels) → **fine-tune on your Mendeley greenhouse set (c2x8rynybg) + Tomato-Village** for real-world detection. Your Mendeley set is the right *target-domain detection* anchor.
2. **Apple:** classifier on **Plant Pathology 2021 (FGVC8)** (field, 6 classes, 18.6k); add boxes from PlantDoc/Roboflow if localization is needed.
3. **Cherry:** start from **PlantVillage cherry + Kaggle cherry-leaves**, but **budget for your own data collection** — public cherry coverage is powdery-mildew-only and lab-only.
4. **Spectral/Brix:** treat as a **build-your-own** track. Use **DeepHS-Fruit** and the **mango DMC** set to choose modeling methods (PLS/CNN on spectra), but plan an **AS7265x + refractometer** calibration campaign — no matched public dataset exists.

---

## Sources

- https://data.mendeley.com/datasets/c2x8rynybg/1
- https://www.sciencedirect.com/science/article/pii/S2352340925007541
- https://www.researchgate.net/publication/395410161_A_Labeled_Image_Dataset_of_Common_Tomato_Diseases_for_Classification_and_Object_Detection
- https://doi.org/10.1016/j.dib.2025.112032
- https://github.com/spMohanty/PlantVillage-Dataset
- https://www.frontiersin.org/journals/plant-science/articles/10.3389/fpls.2016.01419/full
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5032846/
- https://arxiv.org/abs/1511.08060
- https://www.tensorflow.org/datasets/catalog/plant_village
- https://data.mendeley.com/datasets/tywbtsjrjv/1
- https://github.com/pratikkayal/PlantDoc-Dataset
- https://arxiv.org/abs/1911.10317
- https://dl.acm.org/doi/10.1145/3371158.3371196
- https://public.roboflow.com/object-detection/plantdoc
- https://www.kaggle.com/c/plant-pathology-2020-fgvc7
- https://arxiv.org/abs/2004.11958
- https://bsapubs.onlinelibrary.wiley.com/doi/10.1002/aps3.11390
- https://www.kaggle.com/c/plant-pathology-2021-fgvc8
- https://vision.cornell.edu/se3/wp-content/uploads/2021/09/029.pdf
- https://arxiv.org/pdf/2210.00298
- https://link.springer.com/article/10.1007/s00530-023-01158-y
- https://github.com/mamta-joshi-gehlot/Tomato-Village
- https://www.kaggle.com/datasets/mamtag/tomato-village
- https://gts.ai/dataset-download/taiwan-tomato-leaves-dataset/
- https://www.kaggle.com/datasets/cookiefinder/tomato-disease-multiple-sources
- https://www.kaggle.com/datasets/ashishmotwani/tomato
- https://www.kaggle.com/datasets/codeinstitute/cherry-leaves
- https://github.com/cla-cif/Cherry-Powdery-Mildew-Detector
- https://plantvillage.psu.edu/topics/cherry-including-sour/infos
- https://github.com/cogsys-tuebingen/deephs_fruit
- https://cogsys.cs.uni-tuebingen.de/webprojects/DeepHS-Fruit-2023-Datasets/
- https://data.mendeley.com/datasets/y5h6v8w6ms/2
- https://www.sciencedirect.com/science/article/pii/S2352340925005906
- https://data.mendeley.com/datasets/46htwnp833/4
- https://github.com/spectral-datasets/mango-dmc
- https://www.frontiersin.org/journals/plant-science/articles/10.3389/fpls.2025.1634785/full
- https://arxiv.org/html/2606.01231v1

---

**Key callouts for the user:**
- Your Mendeley dataset's real image count is **1,026** (not ~1,206), it's **bounding-box annotated (LabelImg)** across leaves/fruits/stems, **greenhouse** conditions, and **CC BY-NC** (non-commercial — important for a product).
- **Cherry data is the biggest gap**: only ~1,900 PlantVillage lab images + one 4,208-image binary Kaggle set, powdery-mildew-only, no field/fruit data. Plan to collect your own.
- **No public AS7265x / cheap-sensor Brix dataset exists** — the spectral track will require your own calibration data; public spectral sets are all lab hyperspectral/FT-NIR and cover other fruits (no apple/cherry/tomato Brix).
- License strings for most Kaggle/Roboflow sets are **[unverified]** because those pages blocked automated fetch — confirm them manually before any commercial use.
