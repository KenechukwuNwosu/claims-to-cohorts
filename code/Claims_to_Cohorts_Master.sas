/*==============================================================================
CLAIMS TO COHORTS
From Administrative Healthcare Data to Reproducible Analytic Cohorts in SAS

Author: Kenechukwu O. S. Nwosu

MASTER ANALYSIS PROGRAM
==============================================================================*/


/*==============================================================================
SECTION 0. PROJECT CONFIGURATION AND REPRODUCIBILITY SETUP
==============================================================================*/


/*------------------------------------------------------------------------------
0.1 PROJECT VERSION

Change this only when making a meaningful new release of the analysis.

Examples:
1.0.0 = first definitive GitHub release
1.1.0 = methodological update
2.0.0 = major redesign
------------------------------------------------------------------------------*/

%let PROJECT_VERSION=1.0.0;


/*------------------------------------------------------------------------------
0.2 PROJECT ROOT

%sysget(HOME) automatically retrieves the current SAS OnDemand home directory.

For your account this resolves to:

/home/u63890411

Therefore the complete project path becomes:

/home/u63890411/Claims_To_Cohorts

This is preferable to publishing your personal SAS user ID in GitHub code.
------------------------------------------------------------------------------*/

%let HOME=%sysget(HOME);

%let PROJECT_ROOT=&HOME/Claims_To_Cohorts;


/*------------------------------------------------------------------------------
0.3 DEFINE PROJECT SUBFOLDERS
------------------------------------------------------------------------------*/

%let RAWDIR=&PROJECT_ROOT/data_raw;

%let ANALDIR=&PROJECT_ROOT/data_analytic;

%let FIGDIR=&PROJECT_ROOT/figures;

%let TABDIR=&PROJECT_ROOT/tables;

%let REPORTDIR=&PROJECT_ROOT/reports;

%let CODEDIR=&PROJECT_ROOT/code;


/*------------------------------------------------------------------------------
0.4 ASSIGN SAS LIBRARIES

RAW  = original source SAS datasets
ANAL = permanent datasets created by this project
------------------------------------------------------------------------------*/

libname raw "&RAWDIR";

libname anal "&ANALDIR";


/*------------------------------------------------------------------------------
0.5 GENERAL SAS SETTINGS
------------------------------------------------------------------------------*/

options
    nodate
    nonumber
    validvarname=any;


/*------------------------------------------------------------------------------
0.6 GRAPHICS SETTINGS

Standalone PNG figures will be written to the figures directory.
------------------------------------------------------------------------------*/

ods listing gpath="&FIGDIR";

ods graphics /
    reset=all
    imagefmt=png
    width=8in
    height=5in;


/*------------------------------------------------------------------------------
0.7 OPEN THE PROJECT HTML REPORT

This creates the SAS equivalent of the knitted VoiceMark HTML report.

BITMAP_MODE='INLINE' embeds figures in the HTML report itself so the report
remains portable as a single HTML file.

The same figures will also continue to be written separately to FIGDIR for
GitHub README use.
------------------------------------------------------------------------------*/

ods html5
    path="&REPORTDIR"
    file="Claims_to_Cohorts_Report.html"
    style=HTMLBlue
    options(bitmap_mode="inline");


/*------------------------------------------------------------------------------
0.8 PRINT PROJECT CONFIGURATION TO THE SAS LOG
------------------------------------------------------------------------------*/

%put ==========================================================================;
%put CLAIMS TO COHORTS;
%put PROJECT VERSION = &PROJECT_VERSION;
%put PROJECT ROOT    = &PROJECT_ROOT;
%put RAW DATA        = &RAWDIR;
%put ANALYTIC DATA   = &ANALDIR;
%put FIGURES         = &FIGDIR;
%put TABLES          = &TABDIR;
%put REPORTS         = &REPORTDIR;
%put CODE            = &CODEDIR;
%put ==========================================================================;


/*------------------------------------------------------------------------------
0.9 VERIFY LIBRARY ASSIGNMENTS

A return code of 0 means the library was successfully assigned.
------------------------------------------------------------------------------*/

%put RAW LIBRARY RETURN CODE  = %sysfunc(libref(raw));

%put ANAL LIBRARY RETURN CODE = %sysfunc(libref(anal));


/*------------------------------------------------------------------------------
0.10 CREATE A PERMANENT RUN-METADATA DATASET

This records which SAS environment and project version created the outputs.

The dataset will later be exported as part of the reproducibility package.
------------------------------------------------------------------------------*/

data anal.run_metadata;

    length
        project_name $40
        project_version $20
        sas_version $100
        operating_environment $50;


    project_name=
        "Claims to Cohorts";


    project_version=
        "&PROJECT_VERSION";


    run_datetime=
        datetime();


    sas_version=
        "&SYSVLONG4";


    operating_environment=
        "&SYSSCP";


    format
        run_datetime
        e8601dt19.;

run;


/*------------------------------------------------------------------------------
0.11 DISPLAY RUN METADATA
------------------------------------------------------------------------------*/

title "Claims to Cohorts: Reproducibility Metadata";

proc print
    data=anal.run_metadata
    noobs;

run;

title;


/*------------------------------------------------------------------------------
0.12 DISPLAY SOURCE DATASETS

This verifies that SAS can see the intended raw datasets before analysis.
------------------------------------------------------------------------------*/

title "Source Datasets Available in the RAW Library";

proc datasets
    library=raw;

run;

quit;

title;



/*==============================================================================
PROJECT REPORT INTRODUCTION
==============================================================================*/

proc odstext;


    p "Claims to Cohorts"
        /
        style=
        [
            font_size=22pt
            font_weight=bold
        ];


    p "From Administrative Healthcare Data to Reproducible Analytic Cohorts in SAS"
        /
        style=
        [
            font_size=15pt
            font_weight=bold
        ];


    p "Kenechukwu O. S. Nwosu"
        /
        style=
        [
            font_size=12pt
        ];


    p "Claims to Cohorts is a reproducible SAS-based administrative healthcare data project demonstrating how raw enrollment, medical, pharmacy, and hospital-discharge records can be transformed into defensible analytic cohorts for epidemiology, real-world evidence, health economics and outcomes research, pharmacoepidemiology, and health-services research."
        /
        style=
        [
            font_style=italic
        ];


    p "Rather than beginning with a single analysis-ready dataset, the project focuses on decisions that occur upstream of statistical analysis: understanding the unit of observation, validating identifiers, constructing eligible denominators, translating diagnosis and procedure codes into clinical phenotypes, collapsing repeated claims to person-time measures, retaining eligible individuals without observed events, constructing medication exposures, linking facility characteristics, and adapting disease definitions across ICD coding systems."
        /
        style=
        [
            font_style=italic
        ];


    p "Six complementary datasets containing 1,813,866 source records are used. They include synthetic Medicare beneficiary, inpatient, and professional-claims data; a separate pharmacy claims dataset; and real-world Texas inpatient discharge and facility data."
        /
        style=
        [
            font_style=italic
        ];


    p "These datasets are used as complementary methodological examples. They are not treated as one linked patient population."
        /
        style=
        [
            font_style=italic
        ];


    p "Core methodological question:"
        /
        style=
        [
            font_weight=bold
        ];


    p "How can heterogeneous administrative healthcare records be transformed into reproducible, clinically interpretable analytic cohorts suitable for utilization, treatment, screening, medication-exposure, and health-services research?"
        /
        style=
        [
            font_size=13pt
            font_weight=bold
        ];


run;



/*==============================================================================
SECTION 1. DATA SOURCE INVENTORY AND STRUCTURAL AUDIT
==============================================================================*/


/*------------------------------------------------------------------------------
REPORT NARRATIVE — WHY THIS STEP COMES FIRST

PROC ODSTEXT places explanatory prose directly into the HTML report.
These paragraphs are report content, not SAS comments.
------------------------------------------------------------------------------*/

proc odstext;

    p "1. Data Source Inventory and Structural Audit"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "Administrative healthcare datasets can represent very different units of observation. A beneficiary enrollment file may represent beneficiary-years, whereas inpatient and professional files represent healthcare claims, pharmacy data represent dispensing events, and facility files represent hospitals. For that reason, record counts cannot automatically be interpreted as patient counts.";


    p "Before constructing any clinical phenotype or denominator, the analysis therefore begins with a structural audit of every source dataset. The audit verifies which files are available, determines their dimensions, inspects variable names and types, and establishes the data structure that subsequent cohort-construction steps will use.";


    p "This section answers a simple but essential question: What data do we actually have before we begin defining who belongs in a cohort?";

run;


/*==============================================================================
1A. CREATE AN AUTOMATED INVENTORY OF THE RAW DATA LIBRARY
==============================================================================*/

/*
DICTIONARY.TABLES is a SAS metadata table.

Instead of opening each data file and manually counting its rows and columns,
we ask SAS to describe every DATA member currently assigned to the RAW library.

The resulting permanent ANAL.DATASET_INVENTORY dataset contains:

LIBNAME = SAS library containing the dataset
MEMNAME = dataset/member name
NOBS    = number of observations (rows)
NVAR    = number of variables (columns)
*/

title "Claims to Cohorts: Raw Data Inventory";


proc sql;

    create table anal.dataset_inventory as

    select

        libname,

        memname,

        nobs,

        nvar

    from dictionary.tables

    where libname="RAW"
      and memtype="DATA"

    order by memname;

quit;


/*==============================================================================
1B. CALCULATE REPRODUCIBILITY SUMMARY VALUES
==============================================================================*/

/*
NOPRINT tells PROC SQL not to create a visible results table here.

INTO places calculated values into SAS macro variables.

These values will be inserted automatically into the HTML narrative.

This is preferable to manually typing 1,813,866 because if the source files
ever change, the report narrative updates with the actual data.
*/

proc sql noprint;

    select

        count(*),

        strip
        (
            put
            (
                sum(nobs),
                comma20.
            )
        )

    into

        :N_SOURCE_DATASETS trimmed,

        :TOTAL_SOURCE_RECORDS trimmed

    from anal.dataset_inventory;

quit;


/* Write these values into the SAS Log as an additional audit */

%put ==========================================================================;
%put NUMBER OF RAW SOURCE DATASETS = &N_SOURCE_DATASETS;
%put TOTAL SOURCE RECORDS          = &TOTAL_SOURCE_RECORDS;
%put ==========================================================================;


/*==============================================================================
1C. DISPLAY THE DATASET INVENTORY
==============================================================================*/

proc print
    data=anal.dataset_inventory
    noobs
    label;


    var
        memname
        nobs
        nvar;


    label

        memname="Dataset"

        nobs="Rows"

        nvar="Variables";


    format
        nobs
        comma14.;

run;


title;


/*==============================================================================
1D. INSERT THE INVENTORY RESULT INTO THE HTML NARRATIVE
==============================================================================*/

proc odstext;


    p "Source-data summary"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The RAW library contains &N_SOURCE_DATASETS complementary source datasets comprising &TOTAL_SOURCE_RECORDS records. These records should not be interpreted as &TOTAL_SOURCE_RECORDS unique patients because the datasets represent different observational units.";


    p "The Medicare beneficiary file contributes beneficiary-year enrollment information; the Medicare inpatient and professional files contribute healthcare claims; the pharmacy dataset contributes dispensing events; the Texas THCIC inpatient file contributes hospital discharge records; and the accompanying THCIC facility file contributes hospital-level characteristics.";

run;


/*==============================================================================
1E. INSPECT THE STRUCTURE OF EVERY SOURCE DATASET
==============================================================================*/

/*
PROC CONTENTS tells us:

- variable names
- variable order
- character versus numeric type
- variable length
- formats
- labels
- number of observations and variables

POSITION asks SAS to display variables in their physical column order.

These checks are deliberately retained from the successfully completed
analysis.

However, printing all 167 THCIC variables and every variable from all six
datasets would make the final HTML unnecessarily long.

ODS EXCLUDE ALL temporarily hides these verbose listings from the HTML report.
The PROC CONTENTS checks still execute.

ODS EXCLUDE NONE restores normal report output immediately afterward.

The full executable checks remain visible to anyone reading the .sas file.
*/

ods exclude all;


proc contents
    data=raw.cms_bene_sample_2008_2010
    position;
run;


proc contents
    data=raw.cms_carrier_2008_2010_sample
    position;
run;


proc contents
    data=raw.cms_ip_2008_2010_sample
    position;
run;


proc contents
    data=raw.pharmacy
    position;
run;


proc contents
    data=raw.pudf_base1_1q2019
    position;
run;


proc contents
    data=raw.facility_type1q2019
    position;
run;


ods exclude none;


/*==============================================================================
1F. CREATE HUMAN-READABLE DATA-SOURCE LABELS
==============================================================================*/

/*
The actual SAS member names are useful to programmers but unattractive in a
scientific figure.

This DATA step creates a presentation variable called DATA_SOURCE.

SELECT works like a set of IF/ELSE conditions:

If MEMNAME equals a particular SAS dataset name,
assign the corresponding readable label.
*/

data anal.dataset_inventory_plot;

    set anal.dataset_inventory;


    length data_source $45;


    select
    (
        upcase(memname)
    );


        when
        (
            "CMS_BENE_SAMPLE_2008_2010"
        )

            data_source=
            "Medicare beneficiary/member";


        when
        (
            "CMS_CARRIER_2008_2010_SAMPLE"
        )

            data_source=
            "Medicare professional claims";


        when
        (
            "CMS_IP_2008_2010_SAMPLE"
        )

            data_source=
            "Medicare inpatient claims";


        when
        (
            "PHARMACY"
        )

            data_source=
            "Pharmacy claims";


        when
        (
            "PUDF_BASE1_1Q2019"
        )

            data_source=
            "Texas THCIC inpatient";


        when
        (
            "FACILITY_TYPE1Q2019"
        )

            data_source=
            "Texas THCIC facility";


        otherwise

            data_source=
            memname;


    end;

run;


/*==============================================================================
1G. FIGURE 1 — SOURCE-DATA SCALE
==============================================================================*/

/*
RESET=INDEX allows the image name below to be used as the figure filename.

IMAGENAME determines the standalone PNG file written to FIGDIR by the ODS
LISTING destination established in Section 0.

The same plot is also included automatically in the open HTML5 report.
*/

ods graphics /
    reset=index
    imagename="01_dataset_inventory"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.dataset_inventory_plot;


    styleattrs

        datacolors=
        (
            CX2F6BFF
            CX16A085
            CXF39C12
            CXC0392B
            CX8E44AD
            CX27AE60
        );


    vbar data_source /

        response=nobs

        group=data_source

        datalabel

        datalabelattrs=
        (
            weight=bold
        );


    yaxis

        label="Number of records"

        grid;


    xaxis

        label=""

        fitpolicy=rotate;


    keylegend /

        title="Data source"

        position=bottom;


    title
    "Claims to Cohorts: Six Complementary Administrative Data Sources";


    footnote
    "Record counts reflect source rows, not unique patients.";

run;


/* Clear the figure title and footnote so they cannot carry into Section 2 */

title;
footnote;


/*==============================================================================
1H. REPORT INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The six datasets differ substantially in both scale and analytical purpose. The largest source is the Texas THCIC inpatient file, whereas the facility file contains only one record per represented hospital. The Medicare professional file contains substantially more records than the Medicare inpatient file because professional claims capture a broader range of healthcare encounters.";


    p "The inventory therefore illustrates an important administrative-data principle: a larger number of rows does not necessarily mean a larger number of individuals. Each source must be analyzed according to its own unit of observation before records can be aggregated, linked, or interpreted.";


    p "The remainder of the project consequently treats these datasets as complementary analytical modules rather than assuming that every record belongs to one directly linkable longitudinal population.";

run;


/*==============================================================================
END OF SECTION 1
==============================================================================*/



/*==============================================================================
SECTION 2. KEY QUALITY-CONTROL CHECKS
==============================================================================*/


/*------------------------------------------------------------------------------
REPORT NARRATIVE — WHY KEY VALIDATION MATTERS
------------------------------------------------------------------------------*/

proc odstext;

    p "2. Key Quality-Control Checks"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "Administrative healthcare data cannot be checked for duplicates without first defining the expected unit of observation. A repeated identifier may represent a data-quality problem in one file but a legitimate structural feature in another.";


    p "The quality-control strategy therefore uses dataset-specific keys. Beneficiary enrollment records are evaluated at the beneficiary-year level, professional claims are evaluated using claim identifiers, inpatient claims are evaluated using the combination of claim identifier and segment, Texas inpatient discharges are evaluated using RECORD_ID, and facility records are evaluated using THCIC_ID.";


    p "Medicare inpatient claim identifiers are also examined separately for multiple claim segments. These multi-segment claims are not automatically classified as errors because one claim may legitimately contain more than one segment.";

run;


/*==============================================================================
2A. BENEFICIARY PERSON-YEAR DUPLICATES
==============================================================================*/

/*
Expected unit:

one beneficiary
+
one calendar year
=
one beneficiary-year record

GROUP BY collects records sharing the same beneficiary ID and year.

COUNT(*) counts how many such records exist.

HAVING keeps only groups occurring more than once.
*/

proc sql;

    create table anal.qc_bene_duplicates as

    select

        DESYNPUF_ID,

        YEAR,

        count(*) as n

    from raw.cms_bene_sample_2008_2010

    group by

        DESYNPUF_ID,

        YEAR

    having calculated n > 1;

quit;


/*==============================================================================
2B. CARRIER / PROFESSIONAL CLAIM-ID DUPLICATES
==============================================================================*/

/*
For the carrier claims file, CLM_ID is evaluated as the claim identifier.

Any CLM_ID occurring more than once is placed into a QC table for review.

The code does NOT delete these records automatically.
*/

proc sql;

    create table anal.qc_carrier_duplicate_claims as

    select

        CLM_ID,

        count(*) as n

    from raw.cms_carrier_2008_2010_sample

    group by CLM_ID

    having calculated n > 1;

quit;


/*==============================================================================
2C. INPATIENT CLAIM-SEGMENT DUPLICATES
==============================================================================*/

/*
An inpatient claim can contain multiple segments.

Therefore:

CLM_ID alone

is not necessarily an appropriate uniqueness key.

Instead, this QC check evaluates:

CLM_ID + SEGMENT

A repeated combination of BOTH values is more concerning than a repeated
CLM_ID by itself.
*/

proc sql;

    create table anal.qc_ip_duplicate_claim_segments as

    select

        CLM_ID,

        SEGMENT,

        count(*) as n

    from raw.cms_ip_2008_2010_sample

    group by

        CLM_ID,

        SEGMENT

    having calculated n > 1;

quit;


/*==============================================================================
2D. IDENTIFY MULTI-SEGMENT INPATIENT CLAIMS
==============================================================================*/

/*
This is deliberately separate from the duplicate-error check.

Here we ask:

How many CLM_ID values legitimately appear on more than one row?

These are called multi-segment claims in this project and are NOT
automatically treated as duplicate errors.
*/

proc sql;

    create table anal.qc_ip_multisegment_claims as

    select

        CLM_ID,

        count(*) as number_of_segments

    from raw.cms_ip_2008_2010_sample

    group by CLM_ID

    having calculated number_of_segments > 1;

quit;


/*==============================================================================
2E. THCIC INPATIENT RECORD-ID DUPLICATES
==============================================================================*/

/*
RECORD_ID is evaluated as the discharge-record identifier in the THCIC
inpatient file.
*/

proc sql;

    create table anal.qc_thcic_duplicate_records as

    select

        RECORD_ID,

        count(*) as n

    from raw.pudf_base1_1q2019

    group by RECORD_ID

    having calculated n > 1;

quit;


/*==============================================================================
2F. THCIC FACILITY-ID DUPLICATES
==============================================================================*/

/*
THCIC_ID is evaluated as the facility identifier in the accompanying
facility file.

Because the facility file is intended to contribute one set of facility
characteristics per hospital, repeated THCIC_ID values require review.
*/

proc sql;

    create table anal.qc_facility_duplicate_ids as

    select

        THCIC_ID,

        count(*) as n

    from raw.facility_type1q2019

    group by THCIC_ID

    having calculated n > 1;

quit;


/*==============================================================================
2G. DISPLAY THE QUALITY-CONTROL SUMMARY
==============================================================================*/

/*
UNION ALL stacks several query results vertically.

This produces one compact QC table rather than five separate outputs.
*/

proc sql;

    title "Quality-Control Summary";


    select

        "Beneficiary person-year duplicates"
            as Check length=45,

        count(*)
            as Problems

    from anal.qc_bene_duplicates


    union all


    select

        "Carrier duplicate claim IDs",

        count(*)

    from anal.qc_carrier_duplicate_claims


    union all


    select

        "Inpatient duplicate CLM_ID + SEGMENT",

        count(*)

    from anal.qc_ip_duplicate_claim_segments


    union all


    select

        "THCIC duplicate RECORD_ID values",

        count(*)

    from anal.qc_thcic_duplicate_records


    union all


    select

        "Facility duplicate THCIC_ID values",

        count(*)

    from anal.qc_facility_duplicate_ids;

quit;


title;


/*==============================================================================
2H. DISPLAY MULTI-SEGMENT INPATIENT CLAIMS SEPARATELY
==============================================================================*/

proc sql;

    title "Inpatient Claims With More Than One Segment";


    select

        count(*)
            as Multi_Segment_Claim_IDs

    from anal.qc_ip_multisegment_claims;

quit;


title;


/*==============================================================================
2I. STORE QC RESULTS FOR THE HTML REPORT
==============================================================================*/

/*
These PROC SQL NOPRINT queries convert the QC results into macro variables.

Nothing is manually typed into the scientific narrative.

If the data change, the narrative will therefore report the results from
the current execution of the master program.
*/

proc sql noprint;


    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :QC_BENE_DUPLICATES trimmed

    from anal.qc_bene_duplicates;



    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :QC_CARRIER_DUPLICATES trimmed

    from anal.qc_carrier_duplicate_claims;



    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :QC_IP_DUPLICATES trimmed

    from anal.qc_ip_duplicate_claim_segments;



    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :QC_THCIC_DUPLICATES trimmed

    from anal.qc_thcic_duplicate_records;



    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :QC_FACILITY_DUPLICATES trimmed

    from anal.qc_facility_duplicate_ids;



    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :QC_IP_MULTISEGMENT trimmed

    from anal.qc_ip_multisegment_claims;


quit;


/*==============================================================================
2J. WRITE QC RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put QUALITY-CONTROL RESULTS;
%put BENEFICIARY PERSON-YEAR DUPLICATES = &QC_BENE_DUPLICATES;
%put CARRIER CLAIM-ID DUPLICATES        = &QC_CARRIER_DUPLICATES;
%put INPATIENT CLM_ID+SEGMENT DUPLICATES = &QC_IP_DUPLICATES;
%put THCIC RECORD_ID DUPLICATES         = &QC_THCIC_DUPLICATES;
%put FACILITY THCIC_ID DUPLICATES       = &QC_FACILITY_DUPLICATES;
%put MULTI-SEGMENT INPATIENT CLAIM IDS  = &QC_IP_MULTISEGMENT;
%put ==========================================================================;


/*==============================================================================
2K. INSERT THE ACTUAL QC RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Quality-control results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The beneficiary file contained &QC_BENE_DUPLICATES duplicated beneficiary-year keys. The carrier claims file contained &QC_CARRIER_DUPLICATES duplicated claim identifiers. The inpatient claims file contained &QC_IP_DUPLICATES duplicated CLM_ID-plus-SEGMENT combinations.";


    p "The Texas inpatient file contained &QC_THCIC_DUPLICATES duplicated RECORD_ID values, while the facility file contained &QC_FACILITY_DUPLICATES duplicated THCIC_ID values.";


    p "Separately, &QC_IP_MULTISEGMENT inpatient claim identifiers appeared in more than one claim segment. These records were evaluated as a structural feature of the inpatient claims rather than automatically classified as duplicate errors.";

run;


/*==============================================================================
2L. INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The purpose of these checks is not to remove every repeated value. Instead, each dataset is evaluated using the key appropriate to its expected observational unit. This distinction is particularly important for inpatient claims, where a repeated CLM_ID can represent multiple legitimate segments while a repeated CLM_ID-plus-SEGMENT combination would indicate a different potential data-quality problem.";


    p "No records are automatically deleted during this quality-control stage. Potential problems are isolated into dedicated QC datasets so that they remain auditable and can be investigated before cohort construction.";


    p "This approach preserves the source data while making the assumptions about record uniqueness explicit and reproducible.";

run;


/*==============================================================================
END OF SECTION 2
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 3. FORMATS AND CODE-TO-LABEL TRANSLATION
==============================================================================*/


/*------------------------------------------------------------------------------
REPORT NARRATIVE — WHY FORMATS ARE USED
------------------------------------------------------------------------------*/

proc odstext;

    p "3. Code-to-Label Translation"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "Administrative healthcare datasets frequently store categorical information as compact codes rather than descriptive text. These codes are efficient for data storage and exchange but can make analytical output difficult to interpret.";


    p "SAS formats are therefore defined to translate selected coded values into readable labels. Importantly, applying a format does not overwrite the underlying source value. The original administrative code remains available for analysis while tables and figures can display clinically interpretable categories.";


    p "The project defines formats for Medicare sex and race, Texas admission type, and Texas race and ethnicity. Character and numeric formats are kept separate because SAS requires the format type to match the underlying variable type.";

run;


/*==============================================================================
3A. DEFINE PROJECT FORMATS
==============================================================================*/

proc format;


/*------------------------------------------------------------------------------
CMS BENEFICIARY SEX

BENE_SEX_IDENT_CD is CHARACTER in the source data.

The dollar sign before SEXFMT indicates that this is a CHARACTER format.
------------------------------------------------------------------------------*/

    value $sexfmt

        "1"="Male"

        "2"="Female"

        other="Unknown";


/*------------------------------------------------------------------------------
CMS BENEFICIARY RACE

BENE_RACE_CD is CHARACTER in the source data.
------------------------------------------------------------------------------*/

    value $racefmt

        "0"="Unknown"

        "1"="White"

        "2"="Black"

        "3"="Other"

        "4"="Asian"

        "5"="Hispanic"

        "6"="North American Native"

        other="Unknown";


/*------------------------------------------------------------------------------
THCIC TYPE OF ADMISSION

TYPE_OF_ADMISSION is NUMERIC in the successfully analyzed THCIC source file.

Because this is a numeric format, there is NO dollar sign before THCADMIT.
------------------------------------------------------------------------------*/

    value thcadmit

        1="Emergency"

        2="Urgent"

        3="Elective"

        4="Newborn"

        5="Trauma"

        9="Information unavailable"

        other="Unknown";


/*------------------------------------------------------------------------------
THCIC RACE

RACE is CHARACTER in the successfully analyzed THCIC source file.
------------------------------------------------------------------------------*/

    value $thcrace

        "1"="American Indian/Alaska Native"

        "2"="Asian/Pacific Islander"

        "3"="Black"

        "4"="White"

        "5"="Other"

        other="Unknown";


/*------------------------------------------------------------------------------
THCIC ETHNICITY

ETHNICITY is CHARACTER in the successfully analyzed THCIC source file.
------------------------------------------------------------------------------*/

    value $thceth

        "1"="Hispanic"

        "2"="Not Hispanic"

        other="Unknown";

run;


/*==============================================================================
3B. DOCUMENT THE FORMAT DEFINITIONS IN THE SAS LOG
==============================================================================*/

/*
These messages provide a simple reproducibility marker showing that the
format-definition section executed.

They do not change any data.
*/

%put ==========================================================================;
%put CLAIMS TO COHORTS FORMAT DEFINITIONS COMPLETED.;
%put CHARACTER FORMAT: $sexfmt  = CMS beneficiary sex;
%put CHARACTER FORMAT: $racefmt = CMS beneficiary race;
%put NUMERIC FORMAT:   thcadmit  = THCIC admission type;
%put CHARACTER FORMAT: $thcrace = THCIC race;
%put CHARACTER FORMAT: $thceth  = THCIC ethnicity;
%put ==========================================================================;


/*==============================================================================
3C. REPORT INTERPRETATION
==============================================================================*/

proc odstext;

    p "How these formats are used"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The formats defined here serve two related purposes. Some are attached directly to variables so that SAS displays readable labels while retaining the original coded values. Others are later used with the PUT function to create new character variables containing permanent descriptive labels for figures or analytical summaries.";


    p "For example, the Medicare race code remains stored as its original character value in BENE_RACE_CD, but applying the $RACEFMT. format allows a value such as '1' to be displayed as 'White'. In the Texas analysis, the numeric TYPE_OF_ADMISSION code is later passed through the THCADMIT. format to create the readable ADMISSION_TYPE variable.";


    p "Separating storage values from presentation labels improves interpretability without unnecessarily altering the original administrative coding structure.";

run;


/*==============================================================================
END OF SECTION 3
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 4. BUILD THE MEDICARE BENEFICIARY-YEAR DENOMINATOR
==============================================================================*/


/*------------------------------------------------------------------------------
REPORT NARRATIVE — WHY A DENOMINATOR MUST BE BUILT FIRST
------------------------------------------------------------------------------*/

proc odstext;

    p "4. Building the Medicare Beneficiary-Year Denominator"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "Claims files contain healthcare events, but utilization measures require an independently defined population that was eligible to experience those events. Restricting an analysis to beneficiaries who appear in an outcome-specific claims file would exclude individuals with no observed event and would therefore produce an inappropriate denominator.";


    p "The Medicare beneficiary file is used to construct one record per beneficiary-year and to identify full-year fee-for-service eligibility separately for inpatient and professional-claims analyses. Part A eligibility is used for subsequent hospitalization analyses, whereas Part B eligibility is used for the professional-claims screening analysis.";


    p "These eligibility indicators are operational definitions for this portfolio analysis. They allow beneficiaries with and without the outcomes of interest to remain observable in the same denominator.";

run;


/*==============================================================================
4A. CREATE THE BENEFICIARY-YEAR ANALYTIC DATASET
==============================================================================*/

/*
The source beneficiary dataset already contains calendar-year records.

ANAL.MEMBER_YEAR becomes the common denominator dataset used later for:

- AMI hospitalization utilization
- stroke hospitalization utilization
- cervical-screening utilization

The original source data remain untouched in the RAW library.
*/

data anal.member_year;

    set raw.cms_bene_sample_2008_2010;


/*------------------------------------------------------------------------------
CALENDAR YEAR

YEAR already exists in the source file.

This assignment creates/retains the variable used consistently throughout
the downstream analysis.
------------------------------------------------------------------------------*/

    year=YEAR;


/*------------------------------------------------------------------------------
APPROXIMATE AGE AT JULY 1 OF EACH CALENDAR YEAR

MDY(7,1,YEAR) constructs July 1 of the measurement year.

INTCK("YEAR", ..., "C") calculates completed year boundaries continuously,
providing an approximate age at the midpoint of the year.
------------------------------------------------------------------------------*/

    age=
        intck
        (
            "year",
            BENE_BIRTH_DT,
            mdy(7,1,year),
            "c"
        );


/*------------------------------------------------------------------------------
PART A FEE-FOR-SERVICE ELIGIBILITY

Project operational definition:

12 months of Part A coverage
AND
0 months of HMO coverage

This denominator is used for inpatient utilization analyses.
------------------------------------------------------------------------------*/

    part_a_ffs=
        (
            BENE_HI_CVRAGE_TOT_MONS=12
            and
            BENE_HMO_CVRAGE_TOT_MONS=0
        );


/*------------------------------------------------------------------------------
PART B FEE-FOR-SERVICE ELIGIBILITY

Project operational definition:

12 months of Part B coverage
AND
0 months of HMO coverage

This denominator is used for professional-claims analyses.
------------------------------------------------------------------------------*/

    part_b_ffs=
        (
            BENE_SMI_CVRAGE_TOT_MONS=12
            and
            BENE_HMO_CVRAGE_TOT_MONS=0
        );


/*------------------------------------------------------------------------------
FEMALE INDICATOR

BENE_SEX_IDENT_CD="2" corresponds to Female according to the format defined
in Section 3.

This indicator will later be used to construct the illustrative cervical-
screening cohort.
------------------------------------------------------------------------------*/

    female=
        (
            BENE_SEX_IDENT_CD="2"
        );


/*------------------------------------------------------------------------------
APPLY READABLE DISPLAY FORMATS

The underlying coded values remain unchanged.
------------------------------------------------------------------------------*/

    format

        BENE_SEX_IDENT_CD
        $sexfmt.

        BENE_RACE_CD
        $racefmt.;

run;


/*==============================================================================
4B. BASIC BENEFICIARY-YEAR QUALITY CONTROL
==============================================================================*/

/*
These checks do not modify the data.

They verify:

1. the number of rows in MEMBER_YEAR;
2. whether YEAR falls within the expected 2008-2010 period;
3. whether eligibility flags contain only 0/1 values.
*/

proc sql;

    title "Medicare Beneficiary-Year Construction QC";


    select

        count(*)
            as Beneficiary_Year_Records
            format=comma12.,

        min(year)
            as Minimum_Year,

        max(year)
            as Maximum_Year

    from anal.member_year;

quit;


proc freq
    data=anal.member_year;

    tables
        part_a_ffs
        part_b_ffs
        female
        /
        missing;

    title
    "Beneficiary-Year Indicator Quality Control";

run;


title;


/*==============================================================================
4C. ELIGIBILITY COUNTS BY YEAR
==============================================================================*/

proc sql;

    create table anal.member_eligibility_year as

    select

        year,


        count(*)
            as all_member_years,


        sum(part_a_ffs)
            as part_a_ffs_members,


        sum(part_b_ffs)
            as part_b_ffs_members

    from anal.member_year

    group by year

    order by year;

quit;


/*==============================================================================
4D. DISPLAY ELIGIBILITY COUNTS
==============================================================================*/

proc print
    data=anal.member_eligibility_year
    noobs;


    format

        all_member_years

        part_a_ffs_members

        part_b_ffs_members

        comma12.;


    title
    "Eligible Medicare DE-SynPUF Beneficiary-Years";

run;


title;


/*==============================================================================
4E. CALCULATE SUMMARY VALUES FOR THE HTML REPORT
==============================================================================*/

/*
The final report should obtain its counts directly from the current SAS run.

This avoids manually typing the denominator totals into the narrative.
*/

proc sql noprint;

    select

        strip
        (
            put
            (
                sum(all_member_years),
                comma20.
            )
        ),

        strip
        (
            put
            (
                sum(part_a_ffs_members),
                comma20.
            )
        ),

        strip
        (
            put
            (
                sum(part_b_ffs_members),
                comma20.
            )
        )

    into

        :TOTAL_MEMBER_YEARS trimmed,

        :TOTAL_PARTA_FFS trimmed,

        :TOTAL_PARTB_FFS trimmed

    from anal.member_eligibility_year;

quit;


/*------------------------------------------------------------------------------
YEAR-SPECIFIC VALUES FOR THE REPORT
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(all_member_years,comma20.)),
        strip(put(part_a_ffs_members,comma20.)),
        strip(put(part_b_ffs_members,comma20.))

    into

        :MY2008 trimmed,
        :A2008 trimmed,
        :B2008 trimmed

    from anal.member_eligibility_year

    where year=2008;


    select

        strip(put(all_member_years,comma20.)),
        strip(put(part_a_ffs_members,comma20.)),
        strip(put(part_b_ffs_members,comma20.))

    into

        :MY2009 trimmed,
        :A2009 trimmed,
        :B2009 trimmed

    from anal.member_eligibility_year

    where year=2009;


    select

        strip(put(all_member_years,comma20.)),
        strip(put(part_a_ffs_members,comma20.)),
        strip(put(part_b_ffs_members,comma20.))

    into

        :MY2010 trimmed,
        :A2010 trimmed,
        :B2010 trimmed

    from anal.member_eligibility_year

    where year=2010;

quit;


/*==============================================================================
4F. WRITE DENOMINATOR RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put MEDICARE BENEFICIARY-YEAR DENOMINATOR;
%put TOTAL BENEFICIARY-YEARS = &TOTAL_MEMBER_YEARS;
%put TOTAL PART A FFS        = &TOTAL_PARTA_FFS;
%put TOTAL PART B FFS        = &TOTAL_PARTB_FFS;
%put --------------------------------------------------------------------------;
%put 2008 PART A FFS = &A2008;
%put 2009 PART A FFS = &A2009;
%put 2010 PART A FFS = &A2010;
%put --------------------------------------------------------------------------;
%put 2008 PART B FFS = &B2008;
%put 2009 PART B FFS = &B2009;
%put 2010 PART B FFS = &B2010;
%put ==========================================================================;


/*==============================================================================
4G. INSERT THE RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Eligibility results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The Medicare beneficiary source contributed &TOTAL_MEMBER_YEARS beneficiary-year records across 2008-2010.";


    p "Using the project definition of full-year fee-for-service eligibility, &TOTAL_PARTA_FFS beneficiary-years met the Part A criteria used for inpatient analyses, while &TOTAL_PARTB_FFS beneficiary-years met the Part B criteria used for professional-claims analyses.";


    p "Part A eligibility included &A2008 beneficiary-years in 2008, &A2009 in 2009, and &A2010 in 2010. Part B eligibility included &B2008 beneficiary-years in 2008, &B2009 in 2009, and &B2010 in 2010.";

run;


/*==============================================================================
4H. RESHAPE THE ELIGIBILITY TABLE FOR FIGURE 2
==============================================================================*/

/*
The existing table is in WIDE form:

YEAR | ALL_MEMBER_YEARS | PART_A_FFS_MEMBERS | PART_B_FFS_MEMBERS

For the grouped bar chart we create LONG form:

YEAR | ELIGIBILITY_GROUP | ELIGIBLE

Each original year therefore contributes two output rows:
one for Part A and one for Part B.
*/

data anal.member_eligibility_long;

    set anal.member_eligibility_year;


    length eligibility_group $30;


/* Part A row */

    eligibility_group=
        "Full-year Part A FFS";


    eligible=
        part_a_ffs_members;


    output;


/* Part B row */

    eligibility_group=
        "Full-year Part B FFS";


    eligible=
        part_b_ffs_members;


    output;


/* Keep only variables required for the figure */

    keep

        year

        eligibility_group

        eligible;

run;


/*==============================================================================
4I. FIGURE 2 — BENEFICIARY-YEAR ELIGIBILITY
==============================================================================*/

ods graphics /
    reset=index
    imagename="02_member_eligibility"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.member_eligibility_long;


    styleattrs

        datacolors=
        (
            CX2F6BFF
            CX16A085
        );


    vbar year /

        response=eligible

        group=eligibility_group

        groupdisplay=cluster

        datalabel;


    yaxis

        label="Eligible beneficiary-years"

        grid;


    xaxis

        label="Calendar year"

        integer;


    keylegend /

        title=""

        position=bottom;


    title
    "Building the Denominator: Continuously Enrolled FFS Beneficiaries";


    footnote
    "CMS DE-SynPUF; eligibility is defined separately for Part A inpatient and Part B professional-claims analyses.";

run;


title;
footnote;


/*==============================================================================
4J. REPORT INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The denominator becomes smaller after applying full-year fee-for-service requirements because not every beneficiary-year provides the same degree of observable claims experience. Restricting subsequent utilization analyses to beneficiaries meeting the relevant eligibility definition reduces the risk of treating incompletely observable beneficiary-years as though they had complete opportunity for an event to be captured.";


    p "Part A and Part B denominators are retained separately because the later case studies use different claims environments. AMI and stroke hospitalizations are evaluated against the Part A fee-for-service population, whereas the cervical-screening example is constructed from professional claims and therefore uses Part B eligibility.";


    p "This denominator-first design ensures that beneficiaries without an observed outcome remain represented in later analyses. The claims files provide the numerator events; the beneficiary file defines the population in which those events are measured.";

run;


/*==============================================================================
END OF SECTION 4
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 5. CASE STUDY A — ACUTE MYOCARDIAL INFARCTION
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — ANALYTICAL PURPOSE
------------------------------------------------------------------------------*/

proc odstext;

    p "5. Case Study A — Acute Myocardial Infarction"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The first clinical case study demonstrates how a disease phenotype is constructed from inpatient administrative claims and then linked back to an independently defined eligible population.";


    p "Acute myocardial infarction (AMI) is identified from the principal inpatient diagnosis using ICD-9-CM code family 410.x. The analysis additionally searches secondary diagnosis fields for diabetes and searches multiple inpatient procedure fields for percutaneous coronary intervention, cardiac catheterization, and coronary artery bypass grafting.";


    p "The resulting AMI claims are used for two different analytical purposes. First, claim-level treatment categories are summarized descriptively with hospital length of stay. Second, qualifying claims are collapsed to beneficiary-year indicators and linked to the full Part A fee-for-service denominator constructed in Section 4.";


    p "This distinction is important: the inpatient claims identify numerator events, whereas the beneficiary file determines the population in which AMI hospitalization utilization is measured.";

run;


/*==============================================================================
5A. IDENTIFY ACUTE MYOCARDIAL INFARCTION CLAIMS
==============================================================================*/

/*
The historical Medicare DE-SynPUF inpatient data use ICD-9-CM coding.

For this project:

AMI = principal diagnosis beginning with 410

Only admissions during 2008-2010 are retained so that the claims period
matches the beneficiary-year denominator constructed in Section 4.
*/

data anal.ami_claims;

    set raw.cms_ip_2008_2010_sample;


/*------------------------------------------------------------------------------
CREATE CALENDAR YEAR FROM THE ADMISSION DATE
------------------------------------------------------------------------------*/

    year=
        year
        (
            CLM_ADMSN_DT
        );


    if year in
        (
            2008,
            2009,
            2010
        );


/*------------------------------------------------------------------------------
AMI PHENOTYPE

Principal diagnosis ICD-9-CM 410.x

STRIP removes leading and trailing blanks.

SUBSTR(...,1,3) extracts the first three characters.

Therefore values such as:

4100
4101
4109

all satisfy the 410.x phenotype.
------------------------------------------------------------------------------*/

    if substr
       (
           strip
           (
               ICD9_DGNS_CD_1
           ),
           1,
           3
       )="410";


/*==============================================================================
5B. SEARCH SECONDARY DIAGNOSIS FIELDS FOR DIABETES
==============================================================================*/

/*
Diabetes phenotype:

ICD-9-CM 250.x

The inpatient file contains multiple secondary diagnosis positions.

Rather than writing the same IF statement nine separate times, an ARRAY
allows SAS to search ICD9_DGNS_CD_2 through ICD9_DGNS_CD_10 using one loop.
*/

    array dx {*} $

        ICD9_DGNS_CD_2
        -
        ICD9_DGNS_CD_10;


/* Begin by assuming no qualifying diabetes diagnosis */

    diabetes=0;


/* Search every secondary diagnosis field */

    do i=1 to dim(dx);


        if substr
           (
               strip
               (
                   dx{i}
               ),
               1,
               3
           )="250"

        then diabetes=1;


    end;


/*==============================================================================
5C. SEARCH PROCEDURE FIELDS FOR CARDIOVASCULAR INTERVENTIONS
==============================================================================*/

/*
The inpatient file contains six ICD-9-CM procedure positions.

The project identifies:

PCI:
0066
3606
3607
3609

Cardiac catheterization:
3721
3722

CABG:
361.x
*/

    array px {*} $

        ICD9_PRCDR_CD_1
        -
        ICD9_PRCDR_CD_6;


/* Initialize all procedure indicators to zero */

    pci=0;

    catheterization=0;

    cabg=0;


/* Search all six procedure positions */

    do i=1 to dim(px);


        if strip
           (
               px{i}
           )
           in
           (
               "0066",
               "3606",
               "3607",
               "3609"
           )

        then pci=1;


        if strip
           (
               px{i}
           )
           in
           (
               "3721",
               "3722"
           )

        then catheterization=1;


        if substr
           (
               strip
               (
                   px{i}
               ),
               1,
               3
           )="361"

        then cabg=1;


    end;


/*==============================================================================
5D. CALCULATE HOSPITAL LENGTH OF STAY
==============================================================================*/

/*
LOS is calculated as:

discharge date - admission date

For this project, a calculated difference of zero is assigned a LOS of one
day so that same-day stays are represented as one hospital day.
*/

    los=
        NCH_BENE_DSCHRG_DT
        -
        CLM_ADMSN_DT;


    if los=0
        then los=1;


/*==============================================================================
5E. CREATE MUTUALLY EXCLUSIVE TREATMENT CATEGORIES
==============================================================================*/

/*
A claim may contain procedure codes corresponding to more than one procedure
category.

For descriptive presentation, one mutually exclusive category is assigned
using this hierarchy:

CABG
  ↓
PCI
  ↓
Catheterization
  ↓
None

Therefore CABG has the highest classification priority.
*/

    length treatment $20;


    if cabg=1

        then treatment=
        "CABG";


    else if pci=1

        then treatment=
        "PCI";


    else if catheterization=1

        then treatment=
        "Catheterization";


    else

        treatment=
        "None";


/* I is only a loop counter and is not needed in the analytic dataset */

    drop i;

run;


/*==============================================================================
5F. AMI COHORT AUDIT
==============================================================================*/

/*
The audit distinguishes:

- distinct AMI claim IDs;
- distinct beneficiaries represented in the AMI claims;
- AMI claims containing a secondary diabetes diagnosis;
- beneficiaries with AMI claims containing secondary diabetes.
*/

proc sql;

    title "AMI Claims Cohort Audit";


    select

        count
        (
            distinct CLM_ID
        )
            as AMI_Claim_IDs,


        count
        (
            distinct DESYNPUF_ID
        )
            as AMI_Beneficiaries,


        count
        (
            distinct

            case

                when diabetes=1

                then CLM_ID

            end
        )
            as AMI_Claims_with_Diabetes,


        count
        (
            distinct

            case

                when diabetes=1

                then DESYNPUF_ID

            end
        )
            as AMI_Beneficiaries_with_Diabetes

    from anal.ami_claims;

quit;


title;


/*==============================================================================
5G. RECORD-VERSUS-CLAIM STRUCTURE QC
==============================================================================*/

/*
Section 2 established that inpatient claims may contain multiple segments.

This additional check confirms whether the AMI analytic subset contains more
physical rows than distinct claim IDs.

Nothing is deleted or altered.
*/

proc sql;

    title "AMI Record-Level Structure QC";


    select

        count(*)
            as AMI_Rows
            format=comma10.,


        count
        (
            distinct CLM_ID
        )
            as Unique_AMI_Claim_IDs
            format=comma10.,


        calculated AMI_Rows
        -
        calculated Unique_AMI_Claim_IDs
            as Additional_Segment_Rows
            format=comma10.

    from anal.ami_claims;

quit;


title;


/*==============================================================================
5H. VERIFY TREATMENT CLASSIFICATION
==============================================================================*/

/*
Every AMI record should have one of the four treatment labels.

This QC check should therefore return zero missing treatment values.
*/

proc sql;

    title "AMI Treatment Classification QC";


    select

        sum
        (
            missing
            (
                treatment
            )
        )
            as Missing_Treatment_Labels

    from anal.ami_claims;

quit;


title;


/*==============================================================================
5I. SUMMARIZE LENGTH OF STAY BY TREATMENT
==============================================================================*/

proc sql;

    create table anal.ami_treatment_los as

    select

        treatment,


        count(*)
            as n_records,


        count
        (
            distinct CLM_ID
        )
            as n_claim_ids,


        mean
        (
            los
        )
            as mean_los,


        median
        (
            los
        )
            as median_los

    from anal.ami_claims

    group by treatment;

quit;


/* Display the descriptive treatment table */

proc print
    data=anal.ami_treatment_los
    noobs;


    format

        n_records
        n_claim_ids
        comma8.

        mean_los
        median_los
        6.2;


    title
    "AMI Length of Stay by Treatment";

run;


title;


/*==============================================================================
5J. COLLAPSE AMI CLAIMS TO BENEFICIARY-YEAR
==============================================================================*/

/*
The treatment analysis above uses AMI claim records.

Utilization requires a different unit:

one beneficiary
+
one calendar year

A beneficiary with one, two, or more qualifying AMI claims in a year receives:

AMI_HOSPITALIZATION = 1

for that beneficiary-year.
*/

proc sql;

    create table anal.ami_person_year as

    select

        DESYNPUF_ID,

        year,

        max(1)
            as ami_hospitalization

    from anal.ami_claims

    group by

        DESYNPUF_ID,

        year;

quit;


/*==============================================================================
5K. JOIN AMI EVENTS TO THE FULL PART A ELIGIBLE DENOMINATOR
==============================================================================*/

/*
This LEFT JOIN is methodologically essential.

A = every eligible Part A beneficiary-year
B = beneficiary-years containing at least one AMI hospitalization

Beneficiary-years without an AMI event have no matching B record.

COALESCE converts that missing result to zero.

Therefore:

1 = at least one AMI hospitalization
0 = no observed AMI hospitalization

Eligible beneficiary-years with no AMI remain in the denominator.
*/

proc sql;

    create table anal.ami_member_year as

    select

        a.*,


        coalesce
        (
            b.ami_hospitalization,
            0
        )
            as ami_hospitalization

    from anal.member_year as a


    left join anal.ami_person_year as b

        on

        a.DESYNPUF_ID=
        b.DESYNPUF_ID

        and

        a.year=
        b.year


    where a.part_a_ffs=1;

quit;


/*==============================================================================
5L. DENOMINATOR LINKAGE QC
==============================================================================*/

/*
The number of rows in AMI_MEMBER_YEAR should equal the Part A FFS
beneficiary-year denominator created in Section 4.
*/

proc sql;

    title "AMI Denominator Linkage QC";


    select

        count(*)
            as AMI_Analytic_Beneficiary_Years
            format=comma12.,


        sum
        (
            ami_hospitalization
        )
            as AMI_Positive_Beneficiary_Years
            format=comma12.

    from anal.ami_member_year;

quit;


title;


/*==============================================================================
5M. CALCULATE ANNUAL AMI UTILIZATION
==============================================================================*/

/*
For each year:

DENOMINATOR
=
all eligible Part A beneficiary-years

NUMERATOR
=
beneficiary-years with at least one AMI hospitalization

The program calculates both:

percentage with AMI

and

AMI-positive beneficiary-years per 1,000 eligible beneficiary-years.
*/

proc sql;

    create table anal.ami_rate_year as

    select

        year,


        count(*)
            as eligible_beneficiaries,


        sum
        (
            ami_hospitalization
        )
            as beneficiaries_with_ami,


        100
        *
        calculated beneficiaries_with_ami
        /
        calculated eligible_beneficiaries
            as percent_with_ami,


        1000
        *
        calculated beneficiaries_with_ami
        /
        calculated eligible_beneficiaries
            as rate_per_1000

    from anal.ami_member_year

    group by year

    order by year;

quit;


/* Display the annual utilization table */

proc print
    data=anal.ami_rate_year
    noobs;


    format

        eligible_beneficiaries
        beneficiaries_with_ami
        comma10.

        percent_with_ami
        6.3

        rate_per_1000
        6.2;


    title
    "AMI Hospitalization Utilization by Year";

run;


title;


/*==============================================================================
5N. CAPTURE KEY AMI RESULTS FOR THE HTML REPORT
==============================================================================*/

/*
The scientific prose obtains its values directly from the current analysis.

This keeps the report synchronized with the executable program.
*/

proc sql noprint;


    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct CLM_ID
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct DESYNPUF_ID
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct

                    case

                        when diabetes=1

                        then CLM_ID

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct

                    case

                        when diabetes=1

                        then DESYNPUF_ID

                    end
                ),
                comma20.
            )
        )

    into

        :AMI_TOTAL_ROWS trimmed,

        :AMI_TOTAL_CLAIMS trimmed,

        :AMI_TOTAL_BENEFICIARIES trimmed,

        :AMI_DIABETES_CLAIMS trimmed,

        :AMI_DIABETES_BENEFICIARIES trimmed

    from anal.ami_claims;

quit;


/*------------------------------------------------------------------------------
YEAR-SPECIFIC UTILIZATION VALUES
------------------------------------------------------------------------------*/

proc sql noprint;


    select

        strip
        (
            put
            (
                eligible_beneficiaries,
                comma20.
            )
        ),

        strip
        (
            put
            (
                beneficiaries_with_ami,
                comma20.
            )
        ),

        strip
        (
            put
            (
                rate_per_1000,
                6.2
            )
        )

    into

        :AMI_ELIGIBLE_2008 trimmed,

        :AMI_EVENTS_2008 trimmed,

        :AMI_RATE_2008 trimmed

    from anal.ami_rate_year

    where year=2008;



    select

        strip
        (
            put
            (
                eligible_beneficiaries,
                comma20.
            )
        ),

        strip
        (
            put
            (
                beneficiaries_with_ami,
                comma20.
            )
        ),

        strip
        (
            put
            (
                rate_per_1000,
                6.2
            )
        )

    into

        :AMI_ELIGIBLE_2009 trimmed,

        :AMI_EVENTS_2009 trimmed,

        :AMI_RATE_2009 trimmed

    from anal.ami_rate_year

    where year=2009;



    select

        strip
        (
            put
            (
                eligible_beneficiaries,
                comma20.
            )
        ),

        strip
        (
            put
            (
                beneficiaries_with_ami,
                comma20.
            )
        ),

        strip
        (
            put
            (
                rate_per_1000,
                6.2
            )
        )

    into

        :AMI_ELIGIBLE_2010 trimmed,

        :AMI_EVENTS_2010 trimmed,

        :AMI_RATE_2010 trimmed

    from anal.ami_rate_year

    where year=2010;

quit;


/*------------------------------------------------------------------------------
TOTAL AMI-POSITIVE BENEFICIARY-YEARS
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                sum
                (
                    beneficiaries_with_ami
                ),
                comma20.
            )
        )

    into

        :AMI_TOTAL_POSITIVE_BY trimmed

    from anal.ami_rate_year;

quit;


/*==============================================================================
5O. CAPTURE TREATMENT-SPECIFIC RESULTS
==============================================================================*/

/*
Initialize text values before querying.

If a category were absent from a future run, the HTML would display
"Not observed" rather than leaving an unresolved macro variable.
*/

%let AMI_CABG_N=Not observed;
%let AMI_CABG_MEAN=Not observed;
%let AMI_CABG_MEDIAN=Not observed;

%let AMI_PCI_N=Not observed;
%let AMI_PCI_MEAN=Not observed;
%let AMI_PCI_MEDIAN=Not observed;

%let AMI_CATH_N=Not observed;
%let AMI_CATH_MEAN=Not observed;
%let AMI_CATH_MEDIAN=Not observed;

%let AMI_NONE_N=Not observed;
%let AMI_NONE_MEAN=Not observed;
%let AMI_NONE_MEDIAN=Not observed;


/* CABG */

proc sql noprint;

    select

        strip
        (
            put
            (
                n_claim_ids,
                comma20.
            )
        ),

        strip
        (
            put
            (
                mean_los,
                6.2
            )
        ),

        strip
        (
            put
            (
                median_los,
                6.2
            )
        )

    into

        :AMI_CABG_N trimmed,

        :AMI_CABG_MEAN trimmed,

        :AMI_CABG_MEDIAN trimmed

    from anal.ami_treatment_los

    where treatment="CABG";

quit;


/* PCI */

proc sql noprint;

    select

        strip
        (
            put
            (
                n_claim_ids,
                comma20.
            )
        ),

        strip
        (
            put
            (
                mean_los,
                6.2
            )
        ),

        strip
        (
            put
            (
                median_los,
                6.2
            )
        )

    into

        :AMI_PCI_N trimmed,

        :AMI_PCI_MEAN trimmed,

        :AMI_PCI_MEDIAN trimmed

    from anal.ami_treatment_los

    where treatment="PCI";

quit;


/* Catheterization */

proc sql noprint;

    select

        strip
        (
            put
            (
                n_claim_ids,
                comma20.
            )
        ),

        strip
        (
            put
            (
                mean_los,
                6.2
            )
        ),

        strip
        (
            put
            (
                median_los,
                6.2
            )
        )

    into

        :AMI_CATH_N trimmed,

        :AMI_CATH_MEAN trimmed,

        :AMI_CATH_MEDIAN trimmed

    from anal.ami_treatment_los

    where treatment="Catheterization";

quit;


/* No selected procedure */

proc sql noprint;

    select

        strip
        (
            put
            (
                n_claim_ids,
                comma20.
            )
        ),

        strip
        (
            put
            (
                mean_los,
                6.2
            )
        ),

        strip
        (
            put
            (
                median_los,
                6.2
            )
        )

    into

        :AMI_NONE_N trimmed,

        :AMI_NONE_MEAN trimmed,

        :AMI_NONE_MEDIAN trimmed

    from anal.ami_treatment_los

    where treatment="None";

quit;


/*==============================================================================
5P. WRITE KEY AMI RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put ACUTE MYOCARDIAL INFARCTION RESULTS;
%put AMI SOURCE ROWS                     = &AMI_TOTAL_ROWS;
%put DISTINCT AMI CLAIM IDS              = &AMI_TOTAL_CLAIMS;
%put DISTINCT BENEFICIARIES IN AMI FILE  = &AMI_TOTAL_BENEFICIARIES;
%put AMI CLAIMS WITH DIABETES            = &AMI_DIABETES_CLAIMS;
%put AMI BENEFICIARIES WITH DIABETES     = &AMI_DIABETES_BENEFICIARIES;
%put --------------------------------------------------------------------------;
%put 2008 AMI RATE PER 1000 = &AMI_RATE_2008;
%put 2009 AMI RATE PER 1000 = &AMI_RATE_2009;
%put 2010 AMI RATE PER 1000 = &AMI_RATE_2010;
%put --------------------------------------------------------------------------;
%put CABG CLAIMS               = &AMI_CABG_N;
%put PCI CLAIMS                = &AMI_PCI_N;
%put CATHETERIZATION CLAIMS    = &AMI_CATH_N;
%put NO SELECTED PROCEDURE     = &AMI_NONE_N;
%put ==========================================================================;


/*==============================================================================
5Q. INSERT AMI RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "AMI cohort results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The principal-diagnosis ICD-9-CM 410.x phenotype identified &AMI_TOTAL_CLAIMS distinct AMI claim IDs representing &AMI_TOTAL_BENEFICIARIES beneficiaries in the Medicare inpatient data. Secondary-diagnosis screening identified diabetes in &AMI_DIABETES_CLAIMS AMI claims representing &AMI_DIABETES_BENEFICIARIES beneficiaries.";


    p "After collapsing AMI claims to beneficiary-year indicators and linking them to the Part A fee-for-service denominator, &AMI_TOTAL_POSITIVE_BY AMI-positive beneficiary-years were observed across 2008-2010.";


    p "In 2008, &AMI_EVENTS_2008 of &AMI_ELIGIBLE_2008 eligible beneficiary-years contained at least one AMI hospitalization, corresponding to &AMI_RATE_2008 per 1,000. The corresponding rate was &AMI_RATE_2009 per 1,000 in 2009 and &AMI_RATE_2010 per 1,000 in 2010.";


    p "Because the Medicare DE-SynPUF data are synthetic, the annual pattern is presented as a demonstration of claims-based utilization measurement rather than evidence of a true temporal trend in the Medicare population.";

run;


/*==============================================================================
5R. FIGURE 3 — ANNUAL AMI UTILIZATION
==============================================================================*/

ods graphics /
    reset=index
    imagename="03_ami_rate_by_year"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.ami_rate_year;


    series

        x=year

        y=rate_per_1000

        /

        markers

        lineattrs=
        (
            color=CXC0392B
            thickness=4
        )

        markerattrs=
        (
            color=CXC0392B
            symbol=circlefilled
            size=11
        );


    xaxis

        label="Calendar year"

        integer;


    yaxis

        label="Beneficiary-years with at least one AMI hospitalization per 1,000"

        grid

        min=0;


    title
    "AMI Hospitalization Utilization Among Eligible Beneficiaries";


    footnote
    "CMS DE-SynPUF: synthetic data; results demonstrate claims methods, not population inference.";

run;


title;
footnote;


/*==============================================================================
5S. INSERT TREATMENT RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Treatment and hospital length of stay"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The treatment hierarchy classified &AMI_CABG_N AMI claims as CABG, &AMI_PCI_N as PCI, &AMI_CATH_N as cardiac catheterization, and &AMI_NONE_N as having none of the selected procedure categories.";


    p "Mean hospital length of stay was &AMI_CABG_MEAN days for CABG, &AMI_PCI_MEAN days for PCI, &AMI_CATH_MEAN days for catheterization, and &AMI_NONE_MEAN days among claims with no selected procedure. The corresponding median values were &AMI_CABG_MEDIAN, &AMI_PCI_MEDIAN, &AMI_CATH_MEDIAN, and &AMI_NONE_MEDIAN days, respectively.";


    p "These treatment-specific comparisons are descriptive and unadjusted. They should not be interpreted as causal treatment effects because procedure selection is related to clinical severity, anatomy, comorbidity, treatment eligibility, and other factors not controlled in this analysis.";

run;


/*==============================================================================
5T. FIGURE 4 — AMI LENGTH OF STAY BY TREATMENT
==============================================================================*/

ods graphics /
    reset=index
    imagename="04_ami_los_by_treatment"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.ami_treatment_los;


    styleattrs

        datacolors=
        (
            CX95A5A6
            CX3498DB
            CXF39C12
            CXC0392B
        );


    vbar treatment /

        response=mean_los

        group=treatment

        datalabel

        datalabelattrs=
        (
            weight=bold
        )

        categoryorder=respdesc;


    yaxis

        label="Mean length of stay (days)"

        grid

        min=0;


    xaxis

        label="";


    keylegend /

        title=""

        position=bottom;


    title
    "AMI Length of Stay by Treatment Category";


    footnote
    "Descriptive, unadjusted comparison; treatment groups should not be interpreted causally.";

run;


title;
footnote;


/*==============================================================================
5U. FINAL AMI INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The AMI case study demonstrates two distinct levels of claims analysis. At the claim level, diagnosis and procedure fields are searched to construct clinical and treatment phenotypes and to describe hospital utilization. At the beneficiary-year level, repeated claims are collapsed so that each eligible person-year contributes no more than one AMI hospitalization indicator to the annual utilization measure.";


    p "The left join to the Part A denominator is the critical epidemiologic step. Beneficiary-years with qualifying AMI claims receive an event value of one, while eligible beneficiary-years without an AMI claim remain in the analysis with an event value of zero. Without this denominator linkage, the analysis would describe only healthcare users rather than AMI utilization within an observable beneficiary population.";


    p "The treatment hierarchy also illustrates that claims-based classifications require explicit analytical rules when more than one procedure can be recorded. In this project, CABG takes precedence over PCI, which takes precedence over catheterization, producing a mutually exclusive descriptive treatment variable.";


    p "Overall, this module demonstrates diagnosis-code phenotyping, multidimensional array searches, procedure classification, hospital length-of-stay construction, beneficiary-year aggregation, denominator linkage, and annual claims-based utilization measurement within one reproducible SAS workflow.";

run;


/*==============================================================================
END OF SECTION 5
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 6. CASE STUDY B — STROKE
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — ANALYTICAL PURPOSE
------------------------------------------------------------------------------*/

proc odstext;

    p "6. Case Study B — Stroke"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The stroke case study applies the same general claims-analytics architecture used for acute myocardial infarction to a different clinical phenotype. Principal diagnosis codes define qualifying stroke hospitalizations, inpatient procedure fields identify selected reperfusion treatments, and qualifying claims are subsequently collapsed to beneficiary-year indicators for denominator-based utilization measurement.";


    p "For this project, stroke is identified from the principal ICD-9-CM diagnosis using code family 433.x with 433.10 excluded, code family 434.x, or code 436. Inpatient procedure fields are searched for alteplase and mechanical thrombectomy.";


    p "As in the AMI analysis, the claim-level data support descriptive treatment and length-of-stay analyses, whereas annual stroke utilization is estimated only after the claims are collapsed to beneficiary-year indicators and linked to the full Part A fee-for-service denominator.";

run;


/*==============================================================================
6A. IDENTIFY QUALIFYING STROKE CLAIMS
==============================================================================*/

/*
Stroke phenotype used in the successfully completed analysis:

433.x except 433.10
434.x
436

The historical Medicare inpatient data store ICD-9-CM diagnosis codes
without decimal points.

Therefore 433.10 appears in the data as:

43310
*/

data anal.stroke_claims;

    set raw.cms_ip_2008_2010_sample;


/*------------------------------------------------------------------------------
CREATE CALENDAR YEAR
------------------------------------------------------------------------------*/

    year=
        year
        (
            CLM_ADMSN_DT
        );


    if year in
    (
        2008,
        2009,
        2010
    );


/*------------------------------------------------------------------------------
STROKE PHENOTYPE

Condition 1:
Diagnosis begins with 433
BUT is not exactly 43310

OR

Condition 2:
Diagnosis begins with 434

OR

Condition 3:
Diagnosis begins with 436
------------------------------------------------------------------------------*/

    if

       (
           substr
           (
               strip
               (
                   ICD9_DGNS_CD_1
               ),
               1,
               3
           )="433"

           and

           strip
           (
               ICD9_DGNS_CD_1
           )
               ne "43310"
       )

       or

       substr
       (
           strip
           (
               ICD9_DGNS_CD_1
           ),
           1,
           3
       )="434"

       or

       substr
       (
           strip
           (
               ICD9_DGNS_CD_1
           ),
           1,
           3
       )="436";


/*==============================================================================
6B. SEARCH PROCEDURE FIELDS FOR REPERFUSION TREATMENT
==============================================================================*/

/*
The inpatient file contains six ICD-9-CM procedure positions.

Stored procedure codes used in this project:

9910 = Alteplase

3974 = Mechanical thrombectomy

The ARRAY allows all six procedure positions to be searched with one loop.
*/

    array px {*} $

        ICD9_PRCDR_CD_1
        -
        ICD9_PRCDR_CD_6;


/* Begin by assuming neither procedure was identified */

    alteplase=0;

    thrombectomy=0;


/* Search all six procedure positions */

    do i=1 to dim(px);


        if strip
           (
               px{i}
           )="9910"

            then alteplase=1;


        if strip
           (
               px{i}
           )="3974"

            then thrombectomy=1;


    end;


/*==============================================================================
6C. CREATE ANY-INTERVENTION INDICATOR
==============================================================================*/

/*
INTERVENTION becomes:

1 = Alteplase and/or thrombectomy identified
0 = Neither selected reperfusion procedure identified

The variable is retained as a convenient binary summary even though the
more detailed TREATMENT variable is used for the final LOS comparison.
*/

    intervention=
        (
            alteplase=1
            or
            thrombectomy=1
        );


/*==============================================================================
6D. CREATE MUTUALLY EXCLUSIVE TREATMENT GROUP
==============================================================================*/

/*
A claim could theoretically contain both treatment codes.

The mutually exclusive hierarchy is:

Both
  ↓
Thrombectomy
  ↓
Alteplase
  ↓
None
*/

    length treatment $20;


    if alteplase=1
       and thrombectomy=1

        then treatment=
        "Both";


    else if thrombectomy=1

        then treatment=
        "Thrombectomy";


    else if alteplase=1

        then treatment=
        "Alteplase";


    else

        treatment=
        "None";


/*==============================================================================
6E. CALCULATE HOSPITAL LENGTH OF STAY
==============================================================================*/

/*
LOS = discharge date - admission date

As in the AMI module, a calculated value of zero is assigned one day.
*/

    los=
        NCH_BENE_DSCHRG_DT
        -
        CLM_ADMSN_DT;


    if los=0

        then los=1;


    drop i;

run;


/*==============================================================================
6F. STROKE COHORT AUDIT
==============================================================================*/

proc sql;

    title "Stroke Cohort Audit";


    select

        count
        (
            distinct CLM_ID
        )
            as Stroke_Claim_IDs,


        count
        (
            distinct DESYNPUF_ID
        )
            as Stroke_Beneficiaries,


        count
        (
            distinct

            case

                when alteplase=1

                then CLM_ID

            end
        )
            as Alteplase_Claim_IDs,


        count
        (
            distinct

            case

                when thrombectomy=1

                then CLM_ID

            end
        )
            as Thrombectomy_Claim_IDs

    from anal.stroke_claims;

quit;


title;


/*==============================================================================
6G. RECORD-VERSUS-CLAIM STRUCTURE QC
==============================================================================*/

/*
Because Medicare inpatient data can contain claim segments, compare the
number of physical rows with the number of distinct stroke claim IDs.

This is a QC check only. No observations are deleted.
*/

proc sql;

    title "Stroke Record-Level Structure QC";


    select

        count(*)
            as Stroke_Rows
            format=comma10.,


        count
        (
            distinct CLM_ID
        )
            as Unique_Stroke_Claim_IDs
            format=comma10.,


        calculated Stroke_Rows
        -
        calculated Unique_Stroke_Claim_IDs
            as Additional_Segment_Rows
            format=comma10.

    from anal.stroke_claims;

quit;


title;


/*==============================================================================
6H. VERIFY TREATMENT CLASSIFICATION
==============================================================================*/

/*
Every qualifying stroke record should receive one treatment label.

The expected number of missing treatment labels is zero.
*/

proc sql;

    title "Stroke Treatment Classification QC";


    select

        sum
        (
            missing
            (
                treatment
            )
        )
            as Missing_Treatment_Labels

    from anal.stroke_claims;

quit;


title;


/*==============================================================================
6I. COLLAPSE STROKE CLAIMS TO BENEFICIARY-YEAR
==============================================================================*/

/*
For utilization measurement, the unit changes from a stroke claim to a
beneficiary-year.

A beneficiary with one or more qualifying stroke claims during a year
receives:

STROKE_HOSPITALIZATION = 1

for that beneficiary-year.
*/

proc sql;

    create table anal.stroke_person_year as

    select

        DESYNPUF_ID,

        year,

        max(1)
            as stroke_hospitalization

    from anal.stroke_claims

    group by

        DESYNPUF_ID,

        year;

quit;


/*==============================================================================
6J. JOIN STROKE EVENTS TO THE PART A DENOMINATOR
==============================================================================*/

/*
A = all Part A FFS eligible beneficiary-years

B = beneficiary-years with at least one qualifying stroke hospitalization

LEFT JOIN preserves every eligible beneficiary-year.

COALESCE changes a nonmatching stroke value from missing to zero.
*/

proc sql;

    create table anal.stroke_member_year as

    select

        a.*,


        coalesce
        (
            b.stroke_hospitalization,
            0
        )
            as stroke_hospitalization

    from anal.member_year as a


    left join anal.stroke_person_year as b

        on

        a.DESYNPUF_ID=
        b.DESYNPUF_ID

        and

        a.year=
        b.year


    where a.part_a_ffs=1;

quit;


/*==============================================================================
6K. DENOMINATOR LINKAGE QC
==============================================================================*/

/*
The total row count should equal the Part A FFS beneficiary-year denominator
from Section 4.
*/

proc sql;

    title "Stroke Denominator Linkage QC";


    select

        count(*)
            as stroke_analytic_yrs
            label="Stroke Analytic Beneficiary-Years"
            format=comma12.,


        sum
        (
            stroke_hospitalization
        )
            as stroke_positive_yrs
            label="Stroke-Positive Beneficiary-Years"
            format=comma12.

    from anal.stroke_member_year;

quit;


title;


/*==============================================================================
6L. CALCULATE ANNUAL STROKE UTILIZATION
==============================================================================*/

proc sql;

    create table anal.stroke_rate_year as

    select

        year,


        count(*)
            as eligible_beneficiaries,


        sum
        (
            stroke_hospitalization
        )
            as beneficiaries_with_stroke,


        1000
        *
        calculated beneficiaries_with_stroke
        /
        calculated eligible_beneficiaries
            as rate_per_1000

    from anal.stroke_member_year

    group by year

    order by year;

quit;


/* Display annual utilization */

proc print
    data=anal.stroke_rate_year
    noobs;


    format

        eligible_beneficiaries

        beneficiaries_with_stroke

        comma10.

        rate_per_1000

        6.2;


    title
    "Stroke Hospitalization Utilization by Year";

run;


title;


/*==============================================================================
6M. STROKE LENGTH OF STAY BY TREATMENT
==============================================================================*/

proc sql;

    create table anal.stroke_treatment_los as

    select

        treatment,


        count(*)
            as n_records,


        count
        (
            distinct CLM_ID
        )
            as n_claim_ids,


        mean
        (
            los
        )
            as mean_los,


        median
        (
            los
        )
            as median_los

    from anal.stroke_claims

    group by treatment;

quit;


proc print
    data=anal.stroke_treatment_los
    noobs;


    format

        n_records

        n_claim_ids

        comma8.

        mean_los

        median_los

        6.2;


    title
    "Stroke Length of Stay by Treatment";

run;


title;


/*==============================================================================
6N. CAPTURE COHORT RESULTS FOR THE HTML REPORT
==============================================================================*/

proc sql noprint;


    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct CLM_ID
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct DESYNPUF_ID
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct

                    case

                        when alteplase=1

                        then CLM_ID

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct

                    case

                        when thrombectomy=1

                        then CLM_ID

                    end
                ),
                comma20.
            )
        )

    into

        :STROKE_TOTAL_ROWS trimmed,

        :STROKE_TOTAL_CLAIMS trimmed,

        :STROKE_TOTAL_BENEFICIARIES trimmed,

        :STROKE_ALTEPLASE_CLAIMS trimmed,

        :STROKE_THROMBECTOMY_CLAIMS trimmed

    from anal.stroke_claims;

quit;


/*==============================================================================
6O. CAPTURE YEAR-SPECIFIC UTILIZATION RESULTS
==============================================================================*/

proc sql noprint;


    select

        strip
        (
            put
            (
                eligible_beneficiaries,
                comma20.
            )
        ),

        strip
        (
            put
            (
                beneficiaries_with_stroke,
                comma20.
            )
        ),

        strip
        (
            put
            (
                rate_per_1000,
                6.2
            )
        )

    into

        :STROKE_ELIGIBLE_2008 trimmed,

        :STROKE_EVENTS_2008 trimmed,

        :STROKE_RATE_2008 trimmed

    from anal.stroke_rate_year

    where year=2008;



    select

        strip
        (
            put
            (
                eligible_beneficiaries,
                comma20.
            )
        ),

        strip
        (
            put
            (
                beneficiaries_with_stroke,
                comma20.
            )
        ),

        strip
        (
            put
            (
                rate_per_1000,
                6.2
            )
        )

    into

        :STROKE_ELIGIBLE_2009 trimmed,

        :STROKE_EVENTS_2009 trimmed,

        :STROKE_RATE_2009 trimmed

    from anal.stroke_rate_year

    where year=2009;



    select

        strip
        (
            put
            (
                eligible_beneficiaries,
                comma20.
            )
        ),

        strip
        (
            put
            (
                beneficiaries_with_stroke,
                comma20.
            )
        ),

        strip
        (
            put
            (
                rate_per_1000,
                6.2
            )
        )

    into

        :STROKE_ELIGIBLE_2010 trimmed,

        :STROKE_EVENTS_2010 trimmed,

        :STROKE_RATE_2010 trimmed

    from anal.stroke_rate_year

    where year=2010;

quit;


/*------------------------------------------------------------------------------
TOTAL STROKE-POSITIVE BENEFICIARY-YEARS
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                sum
                (
                    beneficiaries_with_stroke
                ),
                comma20.
            )
        )

    into

        :STROKE_TOTAL_POSITIVE_BY trimmed

    from anal.stroke_rate_year;

quit;


/*==============================================================================
6P. CAPTURE TREATMENT-SPECIFIC RESULTS
==============================================================================*/

/*
Conditional aggregation is used here so the code remains valid even when
a treatment category is absent from the observed data.

This is particularly useful because a valid procedure phenotype can return
zero observed claims in a specific sample.
*/

proc sql noprint;

    select


        strip
        (
            put
            (
                sum
                (
                    case

                        when treatment="Alteplase"

                        then n_claim_ids

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                max
                (
                    case

                        when treatment="Alteplase"

                        then mean_los

                        else .

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                max
                (
                    case

                        when treatment="Alteplase"

                        then median_los

                        else .

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when treatment="Thrombectomy"

                        then n_claim_ids

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when treatment="Both"

                        then n_claim_ids

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when treatment="None"

                        then n_claim_ids

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                max
                (
                    case

                        when treatment="None"

                        then mean_los

                        else .

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                max
                (
                    case

                        when treatment="None"

                        then median_los

                        else .

                    end
                ),
                6.2
            )
        )

    into

        :STROKE_ALTEPLASE_N trimmed,

        :STROKE_ALTEPLASE_MEAN trimmed,

        :STROKE_ALTEPLASE_MEDIAN trimmed,

        :STROKE_THROMBECTOMY_N trimmed,

        :STROKE_BOTH_N trimmed,

        :STROKE_NONE_N trimmed,

        :STROKE_NONE_MEAN trimmed,

        :STROKE_NONE_MEDIAN trimmed

    from anal.stroke_treatment_los;

quit;


/*==============================================================================
6Q. WRITE KEY STROKE RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put STROKE RESULTS;
%put STROKE SOURCE ROWS                    = &STROKE_TOTAL_ROWS;
%put DISTINCT STROKE CLAIM IDS             = &STROKE_TOTAL_CLAIMS;
%put DISTINCT BENEFICIARIES IN STROKE FILE = &STROKE_TOTAL_BENEFICIARIES;
%put ALTEPLASE CLAIM IDS                   = &STROKE_ALTEPLASE_CLAIMS;
%put THROMBECTOMY CLAIM IDS                = &STROKE_THROMBECTOMY_CLAIMS;
%put --------------------------------------------------------------------------;
%put 2008 STROKE RATE PER 1000 = &STROKE_RATE_2008;
%put 2009 STROKE RATE PER 1000 = &STROKE_RATE_2009;
%put 2010 STROKE RATE PER 1000 = &STROKE_RATE_2010;
%put --------------------------------------------------------------------------;
%put STROKE-POSITIVE BENEFICIARY-YEARS = &STROKE_TOTAL_POSITIVE_BY;
%put ALTEPLASE TREATMENT CLAIMS        = &STROKE_ALTEPLASE_N;
%put THROMBECTOMY TREATMENT CLAIMS     = &STROKE_THROMBECTOMY_N;
%put BOTH TREATMENTS                   = &STROKE_BOTH_N;
%put NO SELECTED REPERFUSION PROCEDURE = &STROKE_NONE_N;
%put ==========================================================================;


/*==============================================================================
6R. INSERT STROKE UTILIZATION RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Stroke cohort results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The principal-diagnosis stroke phenotype identified &STROKE_TOTAL_CLAIMS distinct qualifying stroke claim IDs representing &STROKE_TOTAL_BENEFICIARIES beneficiaries in the Medicare inpatient data.";


    p "The procedure search identified &STROKE_ALTEPLASE_CLAIMS claim IDs with alteplase and &STROKE_THROMBECTOMY_CLAIMS claim IDs with mechanical thrombectomy.";


    p "After the stroke claims were collapsed to beneficiary-year indicators and linked to the Part A fee-for-service denominator, &STROKE_TOTAL_POSITIVE_BY stroke-positive beneficiary-years were identified across 2008-2010.";


    p "In 2008, &STROKE_EVENTS_2008 of &STROKE_ELIGIBLE_2008 eligible beneficiary-years had at least one qualifying stroke hospitalization, corresponding to &STROKE_RATE_2008 per 1,000. The corresponding rate was &STROKE_RATE_2009 per 1,000 in 2009 and &STROKE_RATE_2010 per 1,000 in 2010.";


    p "Because the Medicare DE-SynPUF data are synthetic, this annual pattern demonstrates claims-based utilization measurement and should not be interpreted as a population-level temporal trend.";

run;


/*==============================================================================
6S. FIGURE 5 — ANNUAL STROKE UTILIZATION
==============================================================================*/

ods graphics /
    reset=index
    imagename="05_stroke_rate_by_year"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.stroke_rate_year;


    series

        x=year

        y=rate_per_1000

        /

        markers

        lineattrs=
        (
            color=CX8E44AD
            thickness=4
        )

        markerattrs=
        (
            color=CX8E44AD
            symbol=circlefilled
            size=11
        );


    xaxis

        label="Calendar year"

        integer;


    yaxis

        label="Beneficiary-years with at least one stroke hospitalization per 1,000"

        grid

        min=0;


    title
    "Stroke Hospitalization Utilization Among Eligible Beneficiaries";


    footnote
    "CMS DE-SynPUF: synthetic data; results demonstrate claims methods, not population inference.";

run;


title;
footnote;


/*==============================================================================
6T. INSERT TREATMENT RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Reperfusion treatment and hospital length of stay"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The treatment classification identified &STROKE_ALTEPLASE_N alteplase-treated claims, &STROKE_THROMBECTOMY_N thrombectomy-treated claims, &STROKE_BOTH_N claims containing both selected reperfusion procedures, and &STROKE_NONE_N claims with neither selected procedure.";


    p "Among alteplase-treated claims, mean hospital length of stay was &STROKE_ALTEPLASE_MEAN days and median length of stay was &STROKE_ALTEPLASE_MEDIAN days. Among claims with no selected reperfusion procedure, mean length of stay was &STROKE_NONE_MEAN days and median length of stay was &STROKE_NONE_MEDIAN days.";


    p "Treatment-specific length-of-stay comparisons are descriptive and unadjusted. Differences should not be interpreted as treatment effects because reperfusion treatment is strongly related to clinical presentation, treatment eligibility, timing, stroke severity, contraindications, and other factors that are not controlled in this portfolio analysis.";

run;


/*==============================================================================
6U. FIGURE 6 — STROKE LENGTH OF STAY BY REPERFUSION TREATMENT
==============================================================================*/

ods graphics /
    reset=index
    imagename="06_stroke_los_by_treatment"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.stroke_treatment_los;


    styleattrs

        datacolors=
        (
            CX95A5A6
            CX2F6BFF
            CXF39C12
            CXC0392B
        );


    vbar treatment /

        response=mean_los

        group=treatment

        datalabel

        categoryorder=respdesc;


    yaxis

        label="Mean length of stay (days)"

        grid

        min=0;


    xaxis

        label="";


    keylegend /

        title=""

        position=bottom;


    title
    "Stroke Length of Stay by Reperfusion Treatment";


    footnote
    "Descriptive, unadjusted comparison; only treatment categories observed in the data are displayed.";

run;


title;
footnote;


/*==============================================================================
6V. FINAL STROKE INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The stroke module demonstrates that the cohort-construction framework developed for AMI is reusable across clinical conditions. The disease definition changes, as do the procedure phenotypes, but the broader workflow remains stable: identify qualifying claims, search repeated procedure positions, construct mutually exclusive treatment categories, derive length of stay, collapse claims to beneficiary-year indicators, and link events to the eligible population.";


    p "The absence of an observed treatment category is itself an analytical result rather than a programming failure. A valid code-search algorithm can return zero qualifying procedures in a particular sample. For that reason, treatment categories are created prospectively in the code, while figures display only categories that are actually represented in the resulting data.";


    p "The beneficiary-year transformation again prevents repeated claims within a year from causing one beneficiary-year to contribute multiple events to the annual binary utilization measure. Eligible beneficiary-years without stroke remain in the denominator with an event value of zero.";


    p "Together with the AMI module, this section demonstrates how a consistent claims-data architecture can support multiple disease phenotypes while preserving transparent, condition-specific code definitions.";

run;


/*==============================================================================
END OF SECTION 6
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 7. CASE STUDY C — PROFESSIONAL CLAIMS AND CERVICAL SCREENING
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — ANALYTICAL PURPOSE
------------------------------------------------------------------------------*/

proc odstext;

    p "7. Case Study C — Professional Claims and Cervical Screening"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The cervical-screening case study introduces a different administrative-data problem from the inpatient AMI and stroke analyses. Screening evidence may appear across multiple professional-claim procedure and diagnosis positions, while eligible beneficiaries without an observed screening claim must remain in the denominator.";


    p "The analysis therefore searches repeated HCPCS/CPT and ICD-9-CM fields for evidence of cytology or HPV-related screening, collapses repeated professional claims to beneficiary-year screening indicators, constructs an illustrative eligible population from the Medicare beneficiary file, and left-joins the claims-derived indicators back to that population.";


    p "For this portfolio methods example, eligibility is defined as full-year Part B fee-for-service enrollment, female sex, and age 21 through 65 years. This is an illustrative claims-utilization cohort and should not be interpreted as a formal HEDIS, USPSTF, or other guideline-concordant screening measure.";

run;


/*==============================================================================
7A. SEARCH PROFESSIONAL CLAIMS FOR CERVICAL-SCREENING EVIDENCE
==============================================================================*/

data anal.carrier_screening_claims;

    set raw.cms_carrier_2008_2010_sample;


/*------------------------------------------------------------------------------
CREATE MEASUREMENT YEAR

The professional claims file uses CLM_FROM_DT as the claim start date.
------------------------------------------------------------------------------*/

    year=
        year
        (
            CLM_FROM_DT
        );


    if year in
    (
        2008,
        2009,
        2010
    );


/*==============================================================================
7B. DEFINE ARRAYS FOR REPEATED CLAIM FIELDS
==============================================================================*/

/*
The successfully analyzed carrier file contains:

HCPCS_CD_1 through HCPCS_CD_13

and

ICD9_DGNS_CD_1 through ICD9_DGNS_CD_8

The arrays allow all positions to be searched without repeating the same
logic separately for every variable.
*/

    array cpt {*} $

        HCPCS_CD_1
        -
        HCPCS_CD_13;


    array dx {*} $

        ICD9_DGNS_CD_1
        -
        ICD9_DGNS_CD_8;


/*------------------------------------------------------------------------------
INITIALIZE SCREENING COMPONENT INDICATORS
------------------------------------------------------------------------------*/

    cytology_cpt=0;

    hpv_cpt=0;

    cytology_diag=0;

    hpv_diag=0;


/*==============================================================================
7C. SEARCH CPT / HCPCS POSITIONS
==============================================================================*/

/*
Cytology-related CPT / HCPCS codes used in the completed analysis.
*/

    do i=1 to dim(cpt);


        if strip
           (
               cpt{i}
           )
           in
           (
               "88141",
               "88142",
               "88143",
               "88147",
               "88148",
               "88150",
               "88152",
               "88153",
               "88154",
               "88155",
               "88164",
               "88165",
               "88166",
               "88167",
               "88174",
               "88175",
               "G0101",
               "G0123",
               "G0124",
               "G0141",
               "G0143",
               "G0144",
               "G0145",
               "G0147",
               "G0148",
               "P3000",
               "P3001",
               "Q0091"
           )

        then cytology_cpt=1;


/* HPV-related procedure codes */

        if strip
           (
               cpt{i}
           )
           in
           (
               "0500T",
               "87620",
               "87621",
               "87622",
               "87624",
               "87625",
               "G0476"
           )

        then hpv_cpt=1;


    end;


/*==============================================================================
7D. SEARCH ICD-9-CM DIAGNOSIS POSITIONS
==============================================================================*/

/*
Diagnosis-based evidence used in the completed analysis:

V762  = cervical cytology-related screening diagnosis
V7381 = HPV-related screening diagnosis

The source values are stored without decimal points.
*/

    do i=1 to dim(dx);


        if strip
           (
               dx{i}
           )="V762"

            then cytology_diag=1;


        if strip
           (
               dx{i}
           )="V7381"

            then hpv_diag=1;


    end;


/*==============================================================================
7E. CREATE FINAL SCREENING INDICATORS
==============================================================================*/

/*
CYTOLOGY = procedure evidence OR diagnosis evidence

HPV = procedure evidence OR diagnosis evidence

CERVICAL_SCREENING = either CYTOLOGY or HPV evidence
*/

    cytology=
        (
            cytology_cpt=1
            or
            cytology_diag=1
        );


    hpv=
        (
            hpv_cpt=1
            or
            hpv_diag=1
        );


    cervical_screening=
        (
            cytology=1
            or
            hpv=1
        );


    drop i;

run;


/*==============================================================================
7F. CLAIM-LEVEL SCREENING QC
==============================================================================*/

/*
This summarizes the indicators before beneficiary-year aggregation.

Nothing is removed or altered.
*/

proc sql;

    title "Professional Claims Cervical-Screening Phenotype QC";


    select

        count(*)
            as carrier_claim_rows
            label="Carrier Claim Rows"
            format=comma12.,


        sum
        (
            cytology
        )
            as cytology_pos_rows
            label="Cytology-Positive Claim Rows"
            format=comma12.,


        sum
        (
            hpv
        )
            as hpv_pos_rows
            label="HPV-Positive Claim Rows"
            format=comma12.,


        sum
        (
            cervical_screening
        )
            as any_screen_pos_rows
            label="Any Screening-Positive Claim Rows"
            format=comma12.

    from anal.carrier_screening_claims;

quit;


title;


/*==============================================================================
7G. COLLAPSE PROFESSIONAL CLAIMS TO BENEFICIARY-YEAR
==============================================================================*/

/*
A beneficiary may have many professional claims during one year.

For the screening-utilization analysis, the unit becomes:

one beneficiary
+
one calendar year

MAX() produces an ever/never indicator within that year.

If any claim contains qualifying evidence:

CERVICAL_SCREENING = 1

Otherwise it remains zero.
*/

proc sql;

    create table anal.cervical_person_year as

    select

        year,

        DESYNPUF_ID,


        max
        (
            cytology
        )
            as cytology,


        max
        (
            hpv
        )
            as hpv,


        max
        (
            cervical_screening
        )
            as cervical_screening

    from anal.carrier_screening_claims

    group by

        year,

        DESYNPUF_ID;

quit;


/*==============================================================================
7H. CONSTRUCT THE ILLUSTRATIVE ELIGIBLE SCREENING COHORT
==============================================================================*/

/*
Project eligibility definition:

Full-year Part B FFS
AND
Female
AND
Age 21 through 65 years

This is deliberately described as an illustrative portfolio methods cohort
rather than a formal preventive-care quality measure.
*/

data anal.cervical_eligible;

    set anal.member_year;


    if part_b_ffs=1
       and
       female=1
       and
       21 <= age
       and
       age <= 65;

run;


/*==============================================================================
7I. ELIGIBILITY QC
==============================================================================*/

proc sql;

    title "Cervical-Screening Eligible Cohort QC";


    select

        count(*)
            as Eligible_Beneficiary_Years
            format=comma12.,


        min(age)
            as Minimum_Age,


        max(age)
            as Maximum_Age

    from anal.cervical_eligible;

quit;


title;


/*==============================================================================
7J. LEFT JOIN SCREENING INDICATORS TO THE ELIGIBLE POPULATION
==============================================================================*/

/*
This is the central epidemiologic step.

A = every eligible beneficiary-year

B = beneficiary-years represented in the carrier claims

The LEFT JOIN retains eligible beneficiaries even if they have no matching
professional claim or no screening evidence.

COALESCE converts missing screening indicators to zero.

Therefore:

1 = qualifying screening evidence observed
0 = no qualifying screening evidence observed
*/

proc sql;

    create table anal.cervical_member_year as

    select

        a.*,


        coalesce
        (
            b.cytology,
            0
        )
            as cytology,


        coalesce
        (
            b.hpv,
            0
        )
            as hpv,


        coalesce
        (
            b.cervical_screening,
            0
        )
            as cervical_screening

    from anal.cervical_eligible as a


    left join anal.cervical_person_year as b

        on

        a.DESYNPUF_ID=
        b.DESYNPUF_ID

        and

        a.year=
        b.year;

quit;


/*==============================================================================
7K. DENOMINATOR LINKAGE AND INDICATOR QC
==============================================================================*/

/*
The number of rows after the LEFT JOIN should equal the number of eligible
beneficiary-years.

The screening indicator should contain only zero and one.
*/

proc sql;

    title "Cervical-Screening Denominator Linkage QC";


    select

        count(*)
            as analytic_yrs
            label="Analytic Beneficiary-Years"
            format=comma12.,


        sum
        (
            cervical_screening
        )
            as screen_positive_yrs
            label="Screening-Positive Beneficiary-Years"
            format=comma12.

    from anal.cervical_member_year;

quit;


proc freq
    data=anal.cervical_member_year;

    tables
        cervical_screening
        /
        missing;

    title
    "Cervical-Screening Indicator QC";

run;


title;


/*==============================================================================
7L. CALCULATE ANNUAL SCREENING UTILIZATION
==============================================================================*/

proc sql;

    create table anal.cervical_rate_year as

    select

        year,


        count(*)
            as eligible,


        sum
        (
            cervical_screening
        )
            as screened,


        100
        *
        calculated screened
        /
        calculated eligible
            as screening_percent

    from anal.cervical_member_year

    group by year

    order by year;

quit;


/* Display annual results */

proc print
    data=anal.cervical_rate_year
    noobs;


    format

        eligible

        screened

        comma10.

        screening_percent

        6.2;


    title
    "Cervical Screening Utilization by Year";

run;


title;


/*==============================================================================
7M. CAPTURE ANNUAL RESULTS FOR THE HTML REPORT
==============================================================================*/

proc sql noprint;


    select

        strip
        (
            put
            (
                sum(eligible),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum(screened),
                comma20.
            )
        ),


        strip
        (
            put
            (
                100
                *
                sum(screened)
                /
                sum(eligible),
                6.2
            )
        )

    into

        :CERV_TOTAL_ELIGIBLE trimmed,

        :CERV_TOTAL_SCREENED trimmed,

        :CERV_OVERALL_PERCENT trimmed

    from anal.cervical_rate_year;

quit;


/*------------------------------------------------------------------------------
2008
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_ELIGIBLE_2008 trimmed,

        :CERV_SCREENED_2008 trimmed,

        :CERV_PERCENT_2008 trimmed

    from anal.cervical_rate_year

    where year=2008;

quit;


/*------------------------------------------------------------------------------
2009
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_ELIGIBLE_2009 trimmed,

        :CERV_SCREENED_2009 trimmed,

        :CERV_PERCENT_2009 trimmed

    from anal.cervical_rate_year

    where year=2009;

quit;


/*------------------------------------------------------------------------------
2010
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_ELIGIBLE_2010 trimmed,

        :CERV_SCREENED_2010 trimmed,

        :CERV_PERCENT_2010 trimmed

    from anal.cervical_rate_year

    where year=2010;

quit;


/*==============================================================================
7N. WRITE ANNUAL RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put CERVICAL-SCREENING RESULTS;
%put TOTAL ELIGIBLE BENEFICIARY-YEARS = &CERV_TOTAL_ELIGIBLE;
%put SCREENING-POSITIVE BENEFICIARY-YEARS = &CERV_TOTAL_SCREENED;
%put OVERALL CLAIM-BASED UTILIZATION = &CERV_OVERALL_PERCENT PERCENT;
%put --------------------------------------------------------------------------;
%put 2008 = &CERV_SCREENED_2008 / &CERV_ELIGIBLE_2008 = &CERV_PERCENT_2008 PERCENT;
%put 2009 = &CERV_SCREENED_2009 / &CERV_ELIGIBLE_2009 = &CERV_PERCENT_2009 PERCENT;
%put 2010 = &CERV_SCREENED_2010 / &CERV_ELIGIBLE_2010 = &CERV_PERCENT_2010 PERCENT;
%put ==========================================================================;


/*==============================================================================
7O. INSERT ANNUAL RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Annual screening-utilization results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The illustrative screening denominator contained &CERV_TOTAL_ELIGIBLE eligible beneficiary-years across 2008-2010. Qualifying cervical-screening evidence was observed in &CERV_TOTAL_SCREENED beneficiary-years, corresponding to an overall claim-based utilization of &CERV_OVERALL_PERCENT percent.";


    p "In 2008, &CERV_SCREENED_2008 of &CERV_ELIGIBLE_2008 eligible beneficiary-years had at least one qualifying screening claim, corresponding to &CERV_PERCENT_2008 percent. The corresponding values were &CERV_SCREENED_2009 of &CERV_ELIGIBLE_2009, or &CERV_PERCENT_2009 percent, in 2009 and &CERV_SCREENED_2010 of &CERV_ELIGIBLE_2010, or &CERV_PERCENT_2010 percent, in 2010.";


    p "These percentages represent observed claims-based utilization within the illustrative eligibility definition. They should not be interpreted as estimates of guideline-concordant cervical-cancer screening prevalence.";

run;


/*==============================================================================
7P. FIGURE 7 — SCREENING UTILIZATION BY YEAR
==============================================================================*/

ods graphics /
    reset=index
    imagename="07_cervical_screening_by_year"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.cervical_rate_year;


    series

        x=year

        y=screening_percent

        /

        markers

        lineattrs=
        (
            color=CX16A085
            thickness=4
        )

        markerattrs=
        (
            color=CX16A085
            symbol=circlefilled
            size=11
        );


    xaxis

        label="Calendar year"

        integer;


    yaxis

        label="Eligible beneficiary-years with at least one screening claim (%)"

        grid

        min=0;


    title
    "Cervical Screening Claims Among an Illustrative Eligible Cohort";


    footnote
    "Portfolio methods example using synthetic CMS DE-SynPUF data; not a formal quality measure.";

run;


title;
footnote;


/*==============================================================================
7Q. CALCULATE SCREENING UTILIZATION BY RACE AND YEAR
==============================================================================*/

proc sql;

    create table anal.cervical_rate_race as

    select

        year,

        BENE_RACE_CD,


        count(*)
            as eligible,


        sum
        (
            cervical_screening
        )
            as screened,


        100
        *
        calculated screened
        /
        calculated eligible
            as screening_percent

    from anal.cervical_member_year

    group by

        year,

        BENE_RACE_CD

    order by

        year,

        BENE_RACE_CD;

quit;


/*==============================================================================
7R. CREATE THE 2010 RACE-SPECIFIC PRESENTATION DATASET
==============================================================================*/

data anal.cervical_race_2010;

    set anal.cervical_rate_race;


    where year=2010;


    length race_label $30;


    race_label=
        put
        (
            BENE_RACE_CD,
            $racefmt.
        );

run;


/* Display 2010 stratified results */

proc print
    data=anal.cervical_race_2010
    noobs;


    var

        race_label

        eligible

        screened

        screening_percent;


    format

        eligible

        screened

        comma10.

        screening_percent

        6.2;


    title
    "Cervical Screening Utilization by Race, 2010";

run;


title;


/*==============================================================================
7S. CAPTURE SELECTED 2010 RACE-SPECIFIC RESULTS
==============================================================================*/

/*
Initialize report values first.

This prevents unresolved macro-variable text if a category is absent in a
future execution.
*/

%let CERV_WHITE_ELIGIBLE=Not observed;
%let CERV_WHITE_SCREENED=Not observed;
%let CERV_WHITE_PERCENT=Not observed;

%let CERV_BLACK_ELIGIBLE=Not observed;
%let CERV_BLACK_SCREENED=Not observed;
%let CERV_BLACK_PERCENT=Not observed;

%let CERV_HISPANIC_ELIGIBLE=Not observed;
%let CERV_HISPANIC_SCREENED=Not observed;
%let CERV_HISPANIC_PERCENT=Not observed;

%let CERV_OTHER_ELIGIBLE=Not observed;
%let CERV_OTHER_SCREENED=Not observed;
%let CERV_OTHER_PERCENT=Not observed;


/*------------------------------------------------------------------------------
WHITE — CMS RACE CODE "1"
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_WHITE_ELIGIBLE trimmed,

        :CERV_WHITE_SCREENED trimmed,

        :CERV_WHITE_PERCENT trimmed

    from anal.cervical_race_2010

    where BENE_RACE_CD="1";

quit;


/*------------------------------------------------------------------------------
BLACK — CMS RACE CODE "2"
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_BLACK_ELIGIBLE trimmed,

        :CERV_BLACK_SCREENED trimmed,

        :CERV_BLACK_PERCENT trimmed

    from anal.cervical_race_2010

    where BENE_RACE_CD="2";

quit;


/*------------------------------------------------------------------------------
OTHER — CMS RACE CODE "3"
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_OTHER_ELIGIBLE trimmed,

        :CERV_OTHER_SCREENED trimmed,

        :CERV_OTHER_PERCENT trimmed

    from anal.cervical_race_2010

    where BENE_RACE_CD="3";

quit;


/*------------------------------------------------------------------------------
HISPANIC — CMS RACE CODE "5"
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip(put(eligible,comma20.)),

        strip(put(screened,comma20.)),

        strip(put(screening_percent,6.2))

    into

        :CERV_HISPANIC_ELIGIBLE trimmed,

        :CERV_HISPANIC_SCREENED trimmed,

        :CERV_HISPANIC_PERCENT trimmed

    from anal.cervical_race_2010

    where BENE_RACE_CD="5";

quit;


/*==============================================================================
7T. INSERT RACE-STRATIFIED RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Race-stratified screening example"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The 2010 beneficiary-year cohort was also summarized by the Medicare race categories available in the source data. Observed screening utilization was &CERV_HISPANIC_PERCENT percent among Hispanic beneficiary-years, &CERV_WHITE_PERCENT percent among White beneficiary-years, &CERV_BLACK_PERCENT percent among Black beneficiary-years, and &CERV_OTHER_PERCENT percent in the Other category.";


    p "The underlying numbers of screening-positive beneficiary-years were &CERV_HISPANIC_SCREENED Hispanic, &CERV_WHITE_SCREENED White, &CERV_BLACK_SCREENED Black, and &CERV_OTHER_SCREENED Other. Because several strata contain very small event counts, these percentages are unstable and should not be interpreted as definitive evidence of population disparities.";


    p "The purpose of this stratification is methodological: it demonstrates how beneficiary characteristics can be carried through cohort construction and used to produce subgroup-specific claims-utilization summaries.";

run;


/*==============================================================================
7U. FIGURE 8 — 2010 SCREENING UTILIZATION BY RACE
==============================================================================*/

ods graphics /
    reset=index
    imagename="08_cervical_screening_race_2010"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.cervical_race_2010;


    styleattrs

        datacolors=
        (
            CX2F6BFF
            CXE67E22
            CX8E44AD
            CX16A085
            CXC0392B
            CX7F8C8D
        );


    vbar race_label /

        response=screening_percent

        group=race_label

        datalabel

        categoryorder=respdesc;


    yaxis

        label="Screening claim utilization (%)"

        grid

        min=0;


    xaxis

        label=""

        fitpolicy=rotate;


    keylegend /

        title=""

        position=bottom;


    title
    "Cervical Screening Utilization by Race, 2010";


    footnote
    "Synthetic CMS DE-SynPUF; small subgroup event counts require cautious interpretation.";

run;


/*------------------------------------------------------------------------------
IMPORTANT

Clear the cervical-screening title and footnote before the pharmacy section.

This prevents the DE-SynPUF screening footnote from carrying into Figure 9.
------------------------------------------------------------------------------*/

title;
footnote;


/*==============================================================================
7V. FINAL INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The cervical-screening module demonstrates why utilization analyses cannot begin only with people who have the service of interest. If the cohort were constructed exclusively from screening claims, beneficiaries without observed screening would disappear and the resulting proportion would not represent utilization within an eligible population.";


    p "Instead, eligibility is defined independently from the beneficiary file, screening evidence is constructed separately from the professional claims, and a left join integrates the two. Eligible beneficiary-years without qualifying screening evidence are retained with a screening indicator of zero.";


    p "The module also demonstrates multidimensional code searching. Screening evidence can occur in any of 13 HCPCS/CPT positions or eight diagnosis positions, making array-based searches more transparent and maintainable than repeated field-specific IF statements.";


    p "Finally, the race-stratified analysis illustrates the difference between producing subgroup estimates and interpreting them. Claims programming can readily generate stratified percentages, but small event counts and synthetic data substantially limit the strength of substantive conclusions that can be drawn from those percentages.";

run;


/*==============================================================================
END OF SECTION 7
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 8. CASE STUDY D — PHARMACY EXPOSURE CONSTRUCTION
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — ANALYTICAL PURPOSE
------------------------------------------------------------------------------*/

proc odstext;

    p "8. Case Study D — Pharmacy Exposure Construction"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The pharmacy module introduces a different administrative-data structure from the Medicare medical claims modules. Here, the primary records are medication-dispensing events rather than diagnosis- or procedure-based healthcare encounters.";


    p "The analysis demonstrates how drug-product identifiers can be standardized, how a medication exposure cohort can be defined from National Drug Codes, how repeated dispensing records can be organized longitudinally within members, and how product-level NDC information can be connected to broader drug-classification systems.";


    p "The pharmacy dataset uses its own member identifier and is analyzed as a separate data source. It is not linked to the Medicare DE-SynPUF beneficiary or medical-claims files.";

run;


/*==============================================================================
8A. STANDARDIZE THE OBSERVED NDC VALUES AND DEFINE BUPROPION EXPOSURE
==============================================================================*/

data anal.pharmacy_clean;

    set raw.pharmacy;


/*------------------------------------------------------------------------------
STANDARDIZE NDC DISPLAY

The observed pharmacy file contains NDC values that can be represented as
11-character product identifiers.

COMPRESS removes hyphens and spaces.

The NDC is retained as CHARACTER so leading zeros are preserved.

Important:
This code standardizes the formatting of the NDC values observed in this
dataset. It is not a general segment-based conversion algorithm for every
possible 10-digit NDC configuration.
------------------------------------------------------------------------------*/

    length ndc11 $11;


    ndc11=
        compress
        (
            strip
            (
                NDC
            ),
            "- "
        );


/*------------------------------------------------------------------------------
BUPROPION EXPOSURE DEFINITION

Two observed product NDCs are included:

00093550101
00185041005
------------------------------------------------------------------------------*/

    bupropion=
        ndc11 in
        (
            "00093550101",
            "00185041005"
        );


/*------------------------------------------------------------------------------
MONTH OF DISPENSING

INTNX moves each fill date to the beginning of its calendar month.

For example:

04APR2011
        ↓
01APR2011

The MONYY7. format subsequently displays this as APR2011.
------------------------------------------------------------------------------*/

    month=
        intnx
        (
            "month",
            filldate,
            0,
            "b"
        );


    format

        month
        monyy7.

        filldate
        date9.;

run;


/*==============================================================================
8B. BASIC PHARMACY EXPOSURE QC
==============================================================================*/

/*
Verify the number of qualifying dispensing records, unique exposed members,
and observed exposure period.

These are descriptive checks only.
*/

proc sql;

    title "Bupropion Exposure Cohort";


    select

        count
        (
            distinct MemberID
        )
            as Unique_Bupropion_Users
            format=comma10.,


        count(*)
            as Total_Bupropion_Fills
            format=comma10.,


        min
        (
            filldate
        )
            as First_Observed_Fill
            format=date9.,


        max
        (
            filldate
        )
            as Last_Observed_Fill
            format=date9.

    from anal.pharmacy_clean

    where bupropion=1;

quit;


title;


/*==============================================================================
8C. CREATE A MEMBER-LEVEL BUPROPION EXPOSURE SUMMARY
==============================================================================*/

/*
This changes the analytical unit from dispensing event to member.

For each exposed member:

INDEX_DATE
=
first observed qualifying bupropion fill

LAST_OBSERVED_FILL
=
last observed qualifying bupropion fill

NUMBER_OF_FILLS
=
number of qualifying dispensing records observed for that member
*/

proc sql;

    create table anal.bupropion_member as

    select

        MemberID,


        min
        (
            filldate
        )
            as index_date
            format=date9.,


        max
        (
            filldate
        )
            as last_observed_fill
            format=date9.,


        count(*)
            as number_of_fills

    from anal.pharmacy_clean

    where bupropion=1

    group by MemberID;

quit;


/*==============================================================================
8D. MEMBER-LEVEL EXPOSURE SUMMARY QC
==============================================================================*/

proc means
    data=anal.bupropion_member
    n
    mean
    median
    min
    max;

    var number_of_fills;

    title
    "Observed Bupropion Fills per Exposed Member";

run;


title;


/*==============================================================================
8E. MONTHLY DISPENSING
==============================================================================*/

/*
For every month, calculate:

FILLS
=
all qualifying bupropion dispensing records

UNIQUE_MEMBERS
=
distinct members with at least one qualifying fill during that month

A member may appear in multiple months, so monthly unique-member counts must
NOT be added together to estimate total unique users.
*/

proc sql;

    create table anal.bupropion_monthly as

    select

        month,


        count(*)
            as fills,


        count
        (
            distinct MemberID
        )
            as unique_members

    from anal.pharmacy_clean

    where bupropion=1

    group by month

    order by month;

quit;


/* Display monthly results */

proc print
    data=anal.bupropion_monthly
    noobs;


    format

        fills
        unique_members
        comma10.;


    title
    "Monthly Bupropion Dispensing";

run;


title;


/*==============================================================================
8F. SAME-DAY DISPENSING QC
==============================================================================*/

/*
The refill-interval analysis below compares consecutive dispensing records.

If a member has more than one qualifying dispensing record on the same date,
the interval between those records will be zero days.

These observations are NOT automatically deleted because the current data do
not establish that they are erroneous duplicates.

Instead, they are isolated and quantified for transparent interpretation.
*/

proc sql;

    create table anal.qc_bupropion_same_day_fills as

    select

        MemberID,

        filldate,

        count(*)
            as number_of_records

    from anal.pharmacy_clean

    where bupropion=1

    group by

        MemberID,

        filldate

    having calculated number_of_records > 1;

quit;


/* Display a compact summary rather than all member-date combinations */

proc sql;

    title "Same-Day Bupropion Dispensing QC";


    select

        count(*)
            as same_day_groups
            label="Member-Date Groups With Multiple Records"
            format=comma10.,


        sum
        (
            number_of_records
        )
            as records_in_groups
            label="Dispensing Records in These Groups"
            format=comma10.,


        max
        (
            number_of_records
        )
            as max_records_one_date
            label="Maximum Records on One Member-Date"

    from anal.qc_bupropion_same_day_fills;

quit;


title;


/*==============================================================================
8G. SORT BUPROPION DISPENSING EVENTS WITHIN MEMBER
==============================================================================*/

/*
The refill calculation requires chronological ordering.

First:

Member A
  → earliest fill
  → next fill
  → next fill

Then:

Member B
  → earliest fill
  → next fill

and so forth.
*/

proc sort

    data=
    anal.pharmacy_clean
    (
        where=
        (
            bupropion=1
        )
    )

    out=anal.bupropion_sorted;


    by

        MemberID

        filldate;

run;


/*==============================================================================
8H. CALCULATE OBSERVED INTERVALS BETWEEN CONSECUTIVE FILLS
==============================================================================*/

/*
LAG(FILLDATE) retrieves the fill date from the previous processed record.

Because the dataset is sorted by MEMBERID and FILLDATE, the previous record
usually represents the previous observed dispensing event for that member.

However, LAG does not automatically know when a new member begins.

Therefore:

IF FIRST.MEMBERID THEN PREVIOUS_FILL=.

resets the previous date at the start of each member.

The final dataset contains only records for which a previous fill exists.
*/

data anal.bupropion_refill_intervals;

    set anal.bupropion_sorted;


    by MemberID;


/* Previous processed fill date */

    previous_fill=
        lag
        (
            filldate
        );


/* Prevent the prior member's fill from carrying into the new member */

    if first.MemberID

        then previous_fill=.;


/* Difference in SAS dates = difference in days */

    days_since_prior_fill=
        filldate
        -
        previous_fill;


/* Keep only observations with a calculable prior-fill interval */

    if not missing
       (
           days_since_prior_fill
       );


    format

        previous_fill
        date9.

        filldate
        date9.;

run;


/*==============================================================================
8I. REFILL-INTERVAL QC AND DESCRIPTIVE SUMMARY
==============================================================================*/

/*
This analysis describes spacing between observed dispensing records.

It is NOT a medication-adherence measure.

Days supply is unavailable, so PDC and MPR are not calculated.
*/

proc means
    data=anal.bupropion_refill_intervals
    n
    mean
    median
    q1
    q3
    min
    max;

    var days_since_prior_fill;

    title
    "Observed Bupropion Refill-Interval Summary";

run;


title;


/* Count zero-day intervals separately */

proc sql;

    title "Observed Refill-Interval QC";


    select

        count(*)
            as Total_Observed_Intervals
            format=comma10.,


        sum
        (
            days_since_prior_fill=0
        )
            as Zero_Day_Intervals
            format=comma10.,


        sum
        (
            days_since_prior_fill>0
        )
            as Positive_Day_Intervals
            format=comma10.

    from anal.bupropion_refill_intervals;

quit;


title;


/*==============================================================================
8J. CREATE NDC → GPI → AHFS CROSSWALK
==============================================================================*/

/*
The crosswalk demonstrates how product-level identifiers can be related to
broader medication-classification variables already present in the source.

DISTINCT prevents identical mappings from being printed repeatedly.
*/

proc sql;

    create table anal.bupropion_crosswalk as

    select distinct

        ndc11,

        GenericName,

        gpi14,

        AhfsClassCode

    from anal.pharmacy_clean

    where bupropion=1

    order by ndc11;

quit;


/* Display the observed mapping */

proc print
    data=anal.bupropion_crosswalk
    noobs;

    title
    "Observed Bupropion NDC, GPI, and AHFS Crosswalk";

run;


title;


/*==============================================================================
8K. CAPTURE KEY PHARMACY RESULTS FOR THE HTML REPORT
==============================================================================*/

proc sql noprint;


    select

        strip
        (
            put
            (
                count
                (
                    distinct MemberID
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count(*),
                comma20.
            )
        ),


        strip
        (
            put
            (
                min
                (
                    filldate
                ),
                date9.
            )
        ),


        strip
        (
            put
            (
                max
                (
                    filldate
                ),
                date9.
            )
        )

    into

        :BUPROPION_USERS trimmed,

        :BUPROPION_FILLS trimmed,

        :BUPROPION_FIRST_DATE trimmed,

        :BUPROPION_LAST_DATE trimmed

    from anal.pharmacy_clean

    where bupropion=1;

quit;


/*------------------------------------------------------------------------------
MEMBER-LEVEL FILL SUMMARY
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                mean
                (
                    number_of_fills
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                median
                (
                    number_of_fills
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                max
                (
                    number_of_fills
                ),
                comma20.
            )
        )

    into

        :BUPROPION_MEAN_FILLS_MEMBER trimmed,

        :BUPROPION_MEDIAN_FILLS_MEMBER trimmed,

        :BUPROPION_MAX_FILLS_MEMBER trimmed

    from anal.bupropion_member;

quit;


/*------------------------------------------------------------------------------
IDENTIFY THE MONTH WITH THE LARGEST NUMBER OF OBSERVED FILLS
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                month,
                monyy7.
            )
        ),

        strip
        (
            put
            (
                fills,
                comma20.
            )
        ),

        strip
        (
            put
            (
                unique_members,
                comma20.
            )
        )

    into

        :BUPROPION_PEAK_MONTH trimmed,

        :BUPROPION_PEAK_FILLS trimmed,

        :BUPROPION_PEAK_MEMBERS trimmed

    from anal.bupropion_monthly

    where fills=
        (
            select
                max(fills)

            from anal.bupropion_monthly
        );

quit;


/*------------------------------------------------------------------------------
REFILL-INTERVAL SUMMARY
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        ),


        strip
        (
            put
            (
                mean
                (
                    days_since_prior_fill
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                median
                (
                    days_since_prior_fill
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    days_since_prior_fill=0
                ),
                comma20.
            )
        )

    into

        :BUPROPION_INTERVAL_N trimmed,

        :BUPROPION_INTERVAL_MEAN trimmed,

        :BUPROPION_INTERVAL_MEDIAN trimmed,

        :BUPROPION_ZERO_INTERVALS trimmed

    from anal.bupropion_refill_intervals;

quit;


/*------------------------------------------------------------------------------
SAME-DAY MEMBER-DATE GROUPS
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        )

    into

        :BUPROPION_SAME_DAY_GROUPS trimmed

    from anal.qc_bupropion_same_day_fills;

quit;


/*==============================================================================
8L. WRITE KEY PHARMACY RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put BUPROPION PHARMACY RESULTS;
%put UNIQUE BUPROPION USERS       = &BUPROPION_USERS;
%put TOTAL QUALIFYING FILLS       = &BUPROPION_FILLS;
%put FIRST OBSERVED FILL          = &BUPROPION_FIRST_DATE;
%put LAST OBSERVED FILL           = &BUPROPION_LAST_DATE;
%put --------------------------------------------------------------------------;
%put MEAN FILLS PER MEMBER        = &BUPROPION_MEAN_FILLS_MEMBER;
%put MEDIAN FILLS PER MEMBER      = &BUPROPION_MEDIAN_FILLS_MEMBER;
%put MAX FILLS FOR ONE MEMBER     = &BUPROPION_MAX_FILLS_MEMBER;
%put --------------------------------------------------------------------------;
%put PEAK MONTH                   = &BUPROPION_PEAK_MONTH;
%put FILLS IN PEAK MONTH          = &BUPROPION_PEAK_FILLS;
%put UNIQUE MEMBERS IN PEAK MONTH = &BUPROPION_PEAK_MEMBERS;
%put --------------------------------------------------------------------------;
%put OBSERVED REFILL INTERVALS    = &BUPROPION_INTERVAL_N;
%put MEAN INTERVAL DAYS           = &BUPROPION_INTERVAL_MEAN;
%put MEDIAN INTERVAL DAYS         = &BUPROPION_INTERVAL_MEDIAN;
%put ZERO-DAY INTERVALS           = &BUPROPION_ZERO_INTERVALS;
%put SAME-DAY MEMBER-DATE GROUPS  = &BUPROPION_SAME_DAY_GROUPS;
%put ==========================================================================;


/*==============================================================================
8M. INSERT EXPOSURE RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Medication-exposure results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The two prespecified bupropion NDCs identified &BUPROPION_USERS unique exposed members and &BUPROPION_FILLS qualifying dispensing records between &BUPROPION_FIRST_DATE and &BUPROPION_LAST_DATE.";


    p "Exposed members had a mean of &BUPROPION_MEAN_FILLS_MEMBER qualifying fills and a median of &BUPROPION_MEDIAN_FILLS_MEMBER fills during the observed data period. The largest observed number of qualifying fills for one member was &BUPROPION_MAX_FILLS_MEMBER.";


    p "The two observed product NDCs mapped to the same generic formulation and GPI but retained distinct AHFS classification codes in the supplied pharmacy data. This crosswalk demonstrates how product-level identifiers can be related to broader medication-classification systems while preserving the original source coding.";

run;


/*==============================================================================
8N. FIGURE 9 — MONTHLY BUPROPION DISPENSING
==============================================================================*/

ods graphics /
    reset=index
    imagename="09_bupropion_monthly_fills"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.bupropion_monthly;


    series

        x=month

        y=fills

        /

        markers

        lineattrs=
        (
            color=CX2F6BFF
            thickness=3
        )

        markerattrs=
        (
            color=CX2F6BFF
            symbol=circlefilled
            size=8
        );


    xaxis

        label="Month"

        fitpolicy=thin;


    yaxis

        label="Observed prescription fills"

        grid

        min=0;


    title
    "Bupropion Dispensing Activity Over Time";


    footnote
    "Separate pharmacy claims dataset; descriptive medication-exposure methods example.";

run;


title;
footnote;


/*==============================================================================
8O. INSERT MONTHLY DISPENSING RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Dispensing over time"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "Monthly bupropion dispensing was relatively stable across most of the observed period, while &BUPROPION_PEAK_MONTH contained the largest number of observed fills: &BUPROPION_PEAK_FILLS dispensing records among &BUPROPION_PEAK_MEMBERS distinct members observed during that month.";


    p "Monthly unique-member counts should not be added together to estimate the total number of exposed members because the same individual can contribute dispensing records in multiple calendar months.";


    p "The pronounced peak in dispensing is reported as an observed feature of the supplied dataset. The available variables do not establish a clinical, administrative, or data-generating explanation for that increase.";

run;


/*==============================================================================
8P. FIGURE 10 — OBSERVED REFILL INTERVALS
==============================================================================*/

ods graphics /
    reset=index
    imagename="10_bupropion_refill_intervals"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.bupropion_refill_intervals;


    histogram days_since_prior_fill /

        fillattrs=
        (
            color=CX16A085
            transparency=0.15
        )

        outline;


    density days_since_prior_fill /

        lineattrs=
        (
            color=CXC0392B
            thickness=3
        );


    xaxis

        label="Days since previous observed fill"

        min=0

        max=180;


    yaxis

        label="Density";


    title
    "Observed Refill Intervals for Bupropion";


    footnote
    "Refill interval is not an adherence measure because days-supply is unavailable.";

run;


title;
footnote;


/*==============================================================================
8Q. INSERT REFILL-INTERVAL RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Observed refill intervals"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "After dispensing records were ordered within member, &BUPROPION_INTERVAL_N intervals between consecutive observed fills were calculated. The median observed interval was &BUPROPION_INTERVAL_MEDIAN days and the mean interval was &BUPROPION_INTERVAL_MEAN days.";


    p "The data also contained &BUPROPION_SAME_DAY_GROUPS member-date combinations with more than one qualifying dispensing record, producing &BUPROPION_ZERO_INTERVALS zero-day intervals in the sequential record-level calculation. These records are retained rather than automatically deleted because the available data do not establish that they are erroneous duplicates.";


    p "The refill-interval distribution should not be interpreted as medication adherence. Days supply is unavailable, so formal adherence measures such as proportion of days covered or medication possession ratio cannot be calculated defensibly from these records alone.";

run;


/*==============================================================================
8R. FINAL PHARMACY INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The pharmacy module demonstrates how the analytical unit changes across healthcare data sources. Whereas the inpatient modules begin with hospitalization claims and the screening module begins with professional claims, this analysis begins with repeated medication-dispensing events.";


    p "Product identifiers are first standardized and used to define the exposure cohort. The same transactions are then summarized at multiple levels: member-level exposure histories, calendar-month dispensing activity, and within-member intervals between successive observed records.";


    p "This multilevel structure illustrates why pharmacy claims analysis requires explicit definitions of exposure, index date, longitudinal order, and the meaning of repeated transactions. A sequence of fill dates can describe observed dispensing behavior without necessarily measuring medication consumption or adherence.";


    p "The crosswalk further demonstrates that drug exposures can be represented simultaneously through product-specific NDCs and broader classification systems such as GPI and AHFS, which can support progressively broader medication phenotypes in future pharmacoepidemiologic analyses.";

run;


/*==============================================================================
END OF SECTION 8
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 9. CASE STUDY E — TEXAS THCIC REAL-WORLD INPATIENT DATA
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — ANALYTICAL PURPOSE
------------------------------------------------------------------------------*/

proc odstext;

    p "9. Case Study E — Texas THCIC Real-World Inpatient Data"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The Texas module extends Claims to Cohorts from synthetic Medicare examples to real-world all-payer hospital discharge data. The analysis combines 2019 Q1 inpatient discharge records with facility-level characteristics and demonstrates facility linkage, ICD-10-CM phenotyping, payer classification, admission-type translation, and hospital resource-use summarization.";


    p "Acute myocardial infarction is identified using principal ICD-10-CM diagnosis I21.x. Unlike the Medicare beneficiary-year analyses, this module is discharge based and does not construct a population denominator. Results therefore describe the observed AMI discharges in 2019 Q1 rather than estimating an annual population hospitalization rate.";


    p "Because only one calendar quarter is analyzed, all Texas results are interpreted descriptively. Facility charges are reported as billed charges and are not treated as payments, reimbursements, or economic costs.";

run;


/*==============================================================================
9A. FACILITY-LINKAGE QUALITY CONTROL
==============================================================================*/

/*
Before creating the analytical dataset, explicitly evaluate how many inpatient
discharge rows match a facility record.

This does not modify either source dataset.

Section 2 already checks whether THCIC_ID is duplicated in the facility file.
Here we evaluate the actual linkage between the two sources.
*/

proc sql;

    create table anal.qc_thcic_facility_linkage as

    select

        count(*)
            as discharge_rows
            format=comma12.,


        sum
        (
            case

                when not missing
                (
                    b.THCIC_ID
                )

                then 1

                else 0

            end
        )
            as matched_facility_rows
            format=comma12.,


        sum
        (
            case

                when missing
                (
                    b.THCIC_ID
                )

                then 1

                else 0

            end
        )
            as unmatched_facility_rows
            format=comma12.

    from raw.pudf_base1_1q2019 as a


    left join raw.facility_type1q2019 as b

        on

        a.THCIC_ID=
        b.THCIC_ID;

quit;


/* Display the linkage summary */

proc print
    data=anal.qc_thcic_facility_linkage
    noobs;

    title
    "THCIC Facility-Linkage Quality Control";

run;


title;


/*==============================================================================
9B. LINK INPATIENT RECORDS TO FACILITY CHARACTERISTICS
==============================================================================*/

/*
Only variables needed for the portfolio analysis are retained.

A = inpatient discharge file
B = facility characteristics file

LEFT JOIN preserves every inpatient discharge even if a facility record does
not match.

The source files remain unchanged.
*/

proc sql;

    create table anal.thcic_core as

    select

        a.RECORD_ID,

        a.THCIC_ID,

        a.TYPE_OF_ADMISSION,

        a.PAT_STATUS,

        a.SEX_CODE,

        a.RACE,

        a.ETHNICITY,

        a.PAT_AGE,

        a.LENGTH_OF_STAY,

        a.FIRST_PAYMENT_SRC,

        a.TOTAL_CHARGES,

        a.PRINC_DIAG_CODE,

        a.EMERGENCY_DEPT_FLAG,


        b.FAC_TEACHING_IND,

        b.FAC_PSYCH_IND,

        b.FAC_REHAB_IND,

        b.FAC_ACUTE_CARE_IND,

        b.FAC_SNF_IND,

        b.FAC_LONG_TERM_AC_IND,

        b.FAC_OTHER_LTC_IND,

        b.FAC_PEDS_IND


    from raw.pudf_base1_1q2019 as a


    left join raw.facility_type1q2019 as b

        on

        a.THCIC_ID=
        b.THCIC_ID;

quit;


/*==============================================================================
9C. DERIVE ANALYSIS VARIABLES
==============================================================================*/

data anal.thcic_core;

    set anal.thcic_core;


    length

        admission_type $30

        payer_group $30

        race_ethnicity $50

        teaching_group $35;


/*------------------------------------------------------------------------------
READABLE ADMISSION TYPE

TYPE_OF_ADMISSION is NUMERIC in the source file used for this analysis.

The THCADMIT. format was defined in Section 3.
------------------------------------------------------------------------------*/

    admission_type=
        put
        (
            TYPE_OF_ADMISSION,
            thcadmit.
        );


/*==============================================================================
9D. CONSTRUCT BROAD PRIMARY-PAYER CATEGORIES
==============================================================================*/

/*
The source variable FIRST_PAYMENT_SRC contains detailed payment-source codes.

For this portfolio analysis, those codes are grouped into broader descriptive
categories.

The original FIRST_PAYMENT_SRC variable is retained.
*/

    select
    (
        upcase
        (
            strip
            (
                FIRST_PAYMENT_SRC
            )
        )
    );


/* Medicare */

        when
        (
            "MA",
            "MB",
            "16"
        )

            payer_group=
            "Medicare";


/* Medicaid */

        when
        (
            "MC"
        )

            payer_group=
            "Medicaid";


/* Private / managed-care grouping */

        when
        (
            "12",
            "13",
            "14",
            "15",
            "HM",
            "BL",
            "CI"
        )

            payer_group=
            "Private/Managed care";


/* Self-pay / charity / unavailable grouping */

        when
        (
            "09",
            "ZZ"
        )

            payer_group=
            "Self-pay/Charity/Unknown";


/* All remaining source codes */

        otherwise

            payer_group=
            "Other";

    end;


/*==============================================================================
9E. CREATE COMBINED RACE / ETHNICITY VARIABLE
==============================================================================*/

/*
RACE and ETHNICITY are CHARACTER variables in the successfully analyzed file.

Project logic:

ETHNICITY = "1"
    → Hispanic

ETHNICITY = "2"
    → use RACE to create a non-Hispanic category

All remaining/suppressed combinations
    → Unknown/Suppressed
*/

    if strip
       (
           ETHNICITY
       )="1"

        then race_ethnicity=
        "Hispanic";


    else if strip
            (
                ETHNICITY
            )="2"

        then do;


            select
            (
                strip
                (
                    RACE
                )
            );


                when
                (
                    "4"
                )

                    race_ethnicity=
                    "Non-Hispanic White";


                when
                (
                    "3"
                )

                    race_ethnicity=
                    "Non-Hispanic Black";


                when
                (
                    "2"
                )

                    race_ethnicity=
                    "Non-Hispanic Asian/Pacific Islander";


                when
                (
                    "1"
                )

                    race_ethnicity=
                    "Non-Hispanic American Indian/Alaska Native";


                when
                (
                    "5"
                )

                    race_ethnicity=
                    "Non-Hispanic Other";


                otherwise

                    race_ethnicity=
                    "Unknown/Suppressed";


            end;


        end;


    else

        race_ethnicity=
        "Unknown/Suppressed";


/*==============================================================================
9F. CREATE FACILITY TEACHING GROUP
==============================================================================*/

/*
The project groups selected FAC_TEACHING_IND values into a readable indicator.

This variable is retained for descriptive or future stratified analyses even
though it is not one of the final headline figures.
*/

    if FAC_TEACHING_IND in
       (
           "A",
           "X"
       )

        then teaching_group=
        "Teaching indicated";


    else

        teaching_group=
        "Not indicated/suppressed";


/*==============================================================================
9G. DEFINE THE ICD-10-CM AMI PHENOTYPE
==============================================================================*/

/*
Texas AMI phenotype:

Principal ICD-10-CM diagnosis beginning with I21

Examples conceptually include:

I210
I211
I219

UPCASE makes the search insensitive to letter case.
*/

    ami_icd10=
        (
            substr
            (
                upcase
                (
                    strip
                    (
                        PRINC_DIAG_CODE
                    )
                ),
                1,
                3
            )
            ="I21"
        );


/* Display charges as US dollars */

    format

        TOTAL_CHARGES
        dollar14.2;

run;


/*==============================================================================
9H. POST-LINKAGE QUALITY CONTROL
==============================================================================*/

/*
This retains your successfully used QC logic.

ROWS_AFTER_LINK should remain consistent with the expected inpatient source
structure.

UNIQUE_RECORD_ID evaluates whether discharge identifiers remain unique after
facility linkage.

ROWS_WITH_FACILITY_DATA counts rows with a nonmissing facility characteristic.
*/

proc sql;

    title
    "THCIC Linkage Quality Control";


    select

        count(*)
            as Rows_After_Link
            format=comma12.,


        count
        (
            distinct RECORD_ID
        )
            as Unique_RECORD_ID
            format=comma12.,


        sum
        (
            not missing
            (
                FAC_ACUTE_CARE_IND
            )
        )
            as Rows_With_Facility_Data
            format=comma12.

    from anal.thcic_core;

quit;


title;


/*==============================================================================
9I. DERIVED-VARIABLE QUALITY CONTROL
==============================================================================*/

/*
Review the distributions of the newly created categorical variables before
restricting to AMI.

These checks help identify unexpected source codes or missing classifications.
*/

proc freq
    data=anal.thcic_core;

    tables

        admission_type

        payer_group

        race_ethnicity

        teaching_group

        ami_icd10

        /

        missing;

    title
    "THCIC Derived-Variable Quality Control";

run;


title;


/*==============================================================================
9J. CREATE THE TEXAS AMI DISCHARGE COHORT
==============================================================================*/

data anal.thcic_ami;

    set anal.thcic_core;


    where ami_icd10=1;

run;


/*==============================================================================
9K. AMI COHORT AUDIT
==============================================================================*/

proc sql;

    title
    "Texas THCIC 2019 Q1 AMI Cohort Size";


    select

        count(*)
            as AMI_Discharges
            format=comma12.,


        count
        (
            distinct THCIC_ID
        )
            as Hospitals_Represented
            format=comma8.

    from anal.thcic_ami;

quit;


title;


/*==============================================================================
9L. DESCRIPTIVE PROFILE
==============================================================================*/

/*
These distributions describe the AMI discharge cohort.

They are not population prevalence estimates because the analytical unit is
a hospital discharge.
*/

proc freq
    data=anal.thcic_ami;

    tables

        admission_type

        payer_group

        race_ethnicity

        EMERGENCY_DEPT_FLAG

        /

        missing;

    title
    "Texas THCIC 2019 Q1 AMI Cohort: Descriptive Profile";

run;


title;


/*------------------------------------------------------------------------------
LOS AND FACILITY CHARGES
------------------------------------------------------------------------------*/

proc means
    data=anal.thcic_ami

    n
    mean
    std
    median
    q1
    q3
    min
    max;


    var

        LENGTH_OF_STAY

        TOTAL_CHARGES;


    title
    "Texas THCIC 2019 Q1 AMI: LOS and Facility Charges";

run;


title;


/*==============================================================================
9M. CREATE PRIMARY-PAYER DISTRIBUTION TABLE
==============================================================================*/

proc freq
    data=anal.thcic_ami
    noprint;


    tables

        payer_group

        /

        out=anal.thcic_ami_payer;

run;


/* Display payer results */

proc print
    data=anal.thcic_ami_payer
    noobs;


    format

        count
        comma10.

        percent
        6.2;


    title
    "Texas THCIC AMI Primary Payer Distribution";

run;


title;


/*==============================================================================
9N. CREATE ADMISSION-TYPE DISTRIBUTION TABLE
==============================================================================*/

proc freq
    data=anal.thcic_ami
    noprint;


    tables

        admission_type

        /

        out=anal.thcic_ami_admission;

run;


/* Display admission results */

proc print
    data=anal.thcic_ami_admission
    noobs;


    format

        count
        comma10.

        percent
        6.2;


    title
    "Texas THCIC AMI Admission-Type Distribution";

run;


title;


/*==============================================================================
9O. SUMMARIZE RESOURCE USE BY PAYER
==============================================================================*/

/*
The analytical unit remains a discharge.

For each payer group calculate:

number of discharges
median length of stay
median facility charges

Median is emphasized because hospital charges can be highly skewed.
*/

proc summary
    data=anal.thcic_ami
    nway;


    class payer_group;


    var

        LENGTH_OF_STAY

        TOTAL_CHARGES;


    output

        out=
        anal.thcic_ami_payer_resource
        (
            drop=
            _TYPE_
            _FREQ_
        )


        n=
        discharges


        median
        (
            LENGTH_OF_STAY
        )
        =
        median_los


        median
        (
            TOTAL_CHARGES
        )
        =
        median_charges;

run;


/* Display payer-specific resource use */

proc print
    data=anal.thcic_ami_payer_resource
    noobs;


    format

        discharges
        comma10.

        median_los
        6.1

        median_charges
        dollar14.2;


    title
    "Texas THCIC AMI Resource Use by Payer";

run;


title;


/*==============================================================================
9P. CAPTURE CORE RESULTS FOR THE HTML REPORT
==============================================================================*/

/*
The report narrative receives its numbers directly from the current run.
*/

proc sql noprint;


    select

        strip
        (
            put
            (
                count(*),
                comma20.
            )
        ),


        strip
        (
            put
            (
                count
                (
                    distinct THCIC_ID
                ),
                comma20.
            )
        )

    into

        :THCIC_AMI_DISCHARGES trimmed,

        :THCIC_AMI_HOSPITALS trimmed

    from anal.thcic_ami;

quit;


/*------------------------------------------------------------------------------
FACILITY-LINKAGE VALUES
------------------------------------------------------------------------------*/

proc sql noprint;

    select

        strip
        (
            put
            (
                discharge_rows,
                comma20.
            )
        ),

        strip
        (
            put
            (
                matched_facility_rows,
                comma20.
            )
        ),

        strip
        (
            put
            (
                unmatched_facility_rows,
                comma20.
            )
        )

    into

        :THCIC_LINK_ROWS trimmed,

        :THCIC_MATCHED_ROWS trimmed,

        :THCIC_UNMATCHED_ROWS trimmed

    from anal.qc_thcic_facility_linkage;

quit;


/*==============================================================================
9Q. CAPTURE PAYER RESULTS
==============================================================================*/

proc sql noprint;

    select


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Medicare"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Medicare"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Private/Managed care"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Private/Managed care"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Self-pay/Charity/Unknown"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Self-pay/Charity/Unknown"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Medicaid"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Medicaid"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Other"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when payer_group="Other"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        )

    into

        :THCIC_MEDICARE_N trimmed,

        :THCIC_MEDICARE_PCT trimmed,

        :THCIC_PRIVATE_N trimmed,

        :THCIC_PRIVATE_PCT trimmed,

        :THCIC_SELFPAY_N trimmed,

        :THCIC_SELFPAY_PCT trimmed,

        :THCIC_MEDICAID_N trimmed,

        :THCIC_MEDICAID_PCT trimmed,

        :THCIC_OTHER_N trimmed,

        :THCIC_OTHER_PCT trimmed

    from anal.thcic_ami_payer;

quit;


/*==============================================================================
9R. CAPTURE ADMISSION-TYPE RESULTS
==============================================================================*/

proc sql noprint;

    select


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type="Emergency"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type="Emergency"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type="Urgent"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type="Urgent"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type="Elective"

                        then count

                        else 0

                    end
                ),
                comma20.
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type="Elective"

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        ),


        strip
        (
            put
            (
                sum
                (
                    case

                        when admission_type in
                        (
                            "Emergency",
                            "Urgent"
                        )

                        then percent

                        else 0

                    end
                ),
                6.2
            )
        )

    into

        :THCIC_EMERGENCY_N trimmed,

        :THCIC_EMERGENCY_PCT trimmed,

        :THCIC_URGENT_N trimmed,

        :THCIC_URGENT_PCT trimmed,

        :THCIC_ELECTIVE_N trimmed,

        :THCIC_ELECTIVE_PCT trimmed,

        :THCIC_ACUTE_ADMISSION_PCT trimmed

    from anal.thcic_ami_admission;

quit;


/*==============================================================================
9S. CAPTURE RESOURCE-USE RANGE
==============================================================================*/

/*
Rather than manually entering payer-specific resource-use values into the
narrative, capture the observed ranges across payer categories.

The detailed payer-specific table remains visible in the HTML.
*/

proc sql noprint;

    select

        strip
        (
            put
            (
                min
                (
                    median_los
                ),
                6.1
            )
        ),


        strip
        (
            put
            (
                max
                (
                    median_los
                ),
                6.1
            )
        ),


        strip
        (
            put
            (
                min
                (
                    median_charges
                ),
                dollar14.2
            )
        ),


        strip
        (
            put
            (
                max
                (
                    median_charges
                ),
                dollar14.2
            )
        )

    into

        :THCIC_MIN_MEDIAN_LOS trimmed,

        :THCIC_MAX_MEDIAN_LOS trimmed,

        :THCIC_MIN_MEDIAN_CHARGE trimmed,

        :THCIC_MAX_MEDIAN_CHARGE trimmed

    from anal.thcic_ami_payer_resource;

quit;


/*==============================================================================
9T. WRITE KEY THCIC RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put TEXAS THCIC AMI RESULTS;
%put AMI DISCHARGES            = &THCIC_AMI_DISCHARGES;
%put HOSPITALS REPRESENTED     = &THCIC_AMI_HOSPITALS;
%put --------------------------------------------------------------------------;
%put SOURCE DISCHARGE ROWS     = &THCIC_LINK_ROWS;
%put FACILITY-MATCHED ROWS     = &THCIC_MATCHED_ROWS;
%put FACILITY-UNMATCHED ROWS   = &THCIC_UNMATCHED_ROWS;
%put --------------------------------------------------------------------------;
%put EMERGENCY                 = &THCIC_EMERGENCY_N / &THCIC_EMERGENCY_PCT PERCENT;
%put URGENT                    = &THCIC_URGENT_N / &THCIC_URGENT_PCT PERCENT;
%put ELECTIVE                  = &THCIC_ELECTIVE_N / &THCIC_ELECTIVE_PCT PERCENT;
%put EMERGENCY + URGENT        = &THCIC_ACUTE_ADMISSION_PCT PERCENT;
%put --------------------------------------------------------------------------;
%put MEDICARE                  = &THCIC_MEDICARE_N / &THCIC_MEDICARE_PCT PERCENT;
%put PRIVATE/MANAGED CARE      = &THCIC_PRIVATE_N / &THCIC_PRIVATE_PCT PERCENT;
%put SELF-PAY/CHARITY/UNKNOWN  = &THCIC_SELFPAY_N / &THCIC_SELFPAY_PCT PERCENT;
%put MEDICAID                  = &THCIC_MEDICAID_N / &THCIC_MEDICAID_PCT PERCENT;
%put OTHER                     = &THCIC_OTHER_N / &THCIC_OTHER_PCT PERCENT;
%put --------------------------------------------------------------------------;
%put MEDIAN LOS RANGE          = &THCIC_MIN_MEDIAN_LOS TO &THCIC_MAX_MEDIAN_LOS DAYS;
%put MEDIAN CHARGE RANGE       = &THCIC_MIN_MEDIAN_CHARGE TO &THCIC_MAX_MEDIAN_CHARGE;
%put ==========================================================================;


/*==============================================================================
9U. INSERT COHORT RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Texas AMI cohort"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The principal-diagnosis ICD-10-CM I21.x phenotype identified &THCIC_AMI_DISCHARGES AMI discharges across &THCIC_AMI_HOSPITALS represented hospitals in the 2019 Q1 Texas inpatient data.";


    p "The facility-linkage audit evaluated &THCIC_LINK_ROWS inpatient discharge rows. Of these, &THCIC_MATCHED_ROWS matched a facility identifier and &THCIC_UNMATCHED_ROWS did not match an accompanying facility record.";


    p "The analytical unit in this module is a hospital discharge. Consequently, the cohort size should not be interpreted as a count of unique Texas residents, and the analysis does not estimate population incidence or an annual hospitalization rate.";

run;


/*==============================================================================
9V. FIGURE 11 — PRIMARY PAYER MIX
==============================================================================*/

ods graphics /
    reset=index
    imagename="11_thcic_ami_payer_mix"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.thcic_ami_payer;


    styleattrs

        datacolors=
        (
            CX2F6BFF
            CX16A085
            CXF39C12
            CXC0392B
            CX8E44AD
        );


    vbar payer_group /

        response=percent

        group=payer_group

        datalabel

        categoryorder=respdesc;


    yaxis

        label="Share of AMI discharges (%)"

        grid

        min=0;


    xaxis

        label=""

        fitpolicy=rotate;


    keylegend /

        title=""

        position=bottom;


    title
    "Texas AMI Discharges Span Multiple Payer Types";


    footnote
    "THCIC 2019 Q1; descriptive single-quarter analysis.";

run;


title;
footnote;


/*==============================================================================
9W. INSERT PAYER RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Primary payer"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "Medicare was the largest primary-payer group, accounting for &THCIC_MEDICARE_N discharges, or &THCIC_MEDICARE_PCT percent of the AMI cohort. Private or managed-care coverage accounted for &THCIC_PRIVATE_N discharges (&THCIC_PRIVATE_PCT percent), followed by self-pay, charity, or unknown payment sources with &THCIC_SELFPAY_N discharges (&THCIC_SELFPAY_PCT percent). Medicaid accounted for &THCIC_MEDICAID_N discharges (&THCIC_MEDICAID_PCT percent), while the remaining &THCIC_OTHER_N discharges (&THCIC_OTHER_PCT percent) were grouped as Other.";


    p "These categories are broad analytical groupings created from the detailed FIRST_PAYMENT_SRC codes in the source data. They are intended to support descriptive payer comparisons within this project.";

run;


/*==============================================================================
9X. FIGURE 12 — ADMISSION TYPE
==============================================================================*/

ods graphics /
    reset=index
    imagename="12_thcic_ami_admission_type"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.thcic_ami_admission;


    styleattrs

        datacolors=
        (
            CXC0392B
            CXF39C12
            CX16A085
            CX8E44AD
            CX7F8C8D
        );


    vbar admission_type /

        response=percent

        group=admission_type

        datalabel

        categoryorder=respdesc;


    yaxis

        label="Share of AMI discharges (%)"

        grid

        min=0;


    xaxis

        label=""

        fitpolicy=rotate;


    keylegend /

        title=""

        position=bottom;


    title
    "Texas AMI Hospitalizations by Admission Type";


    footnote
    "THCIC 2019 Q1; descriptive single-quarter analysis.";

run;


title;
footnote;


/*==============================================================================
9Y. INSERT ADMISSION-TYPE RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Admission type"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "Emergency admissions accounted for &THCIC_EMERGENCY_N AMI discharges (&THCIC_EMERGENCY_PCT percent), while &THCIC_URGENT_N discharges (&THCIC_URGENT_PCT percent) were classified as urgent. Together, emergency and urgent admissions represented &THCIC_ACUTE_ADMISSION_PCT percent of the observed AMI cohort.";


    p "Elective admissions accounted for &THCIC_ELECTIVE_N discharges, or &THCIC_ELECTIVE_PCT percent. The predominance of emergency and urgent admission types is descriptively consistent with AMI as an acute clinical presentation, but the single-quarter analysis is not intended as a hospital-performance comparison.";

run;


/*==============================================================================
9Z. FIGURE 13 — MEDIAN FACILITY CHARGES BY PAYER
==============================================================================*/

ods graphics /
    reset=index
    imagename="13_thcic_ami_median_charges"
    imagefmt=png
    width=8in
    height=5in;


proc sgplot
    data=anal.thcic_ami_payer_resource;


    styleattrs

        datacolors=
        (
            CX2F6BFF
            CX16A085
            CXF39C12
            CXC0392B
            CX8E44AD
        );


    vbar payer_group /

        response=median_charges

        group=payer_group

        datalabel

        categoryorder=respdesc;


    yaxis

        label="Median facility charges (US dollars)"

        grid;


    xaxis

        label=""

        fitpolicy=rotate;


    keylegend /

        title=""

        position=bottom;


    title
    "Median Facility Charges for Texas AMI Discharges by Payer Group";


    footnote
    "Charges are not payments or costs; THCIC 2019 Q1.";

run;


title;
footnote;


/*==============================================================================
9AA. INSERT RESOURCE-USE RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Resource utilization"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "Across the payer categories, median hospital length of stay ranged from &THCIC_MIN_MEDIAN_LOS to &THCIC_MAX_MEDIAN_LOS days. Median facility charges ranged from &THCIC_MIN_MEDIAN_CHARGE to &THCIC_MAX_MEDIAN_CHARGE.";


    p "Facility charges represent amounts billed by hospitals and should not be interpreted as the economic cost of providing care, the amount reimbursed by an insurer, or the amount ultimately paid. The payer-specific summaries are therefore descriptive measures of recorded facility charges rather than comparative cost-effectiveness estimates.";

run;


/*==============================================================================
9AB. FINAL THCIC INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The Texas module demonstrates how claims-style analytical methods extend into a real-world hospital-discharge environment. Unlike the Medicare modules, the analysis begins with a large all-payer discharge file and enriches those records through facility-level linkage before constructing the clinical phenotype.";


    p "The module also demonstrates the transition from ICD-9-CM to ICD-10-CM. The clinical concept of acute myocardial infarction remains the same, but its operational definition changes from the historical Medicare 410.x phenotype to principal ICD-10-CM diagnosis I21.x in the Texas data.";


    p "Payer categories, admission type, race and ethnicity, facility characteristics, length of stay, and charges illustrate the broader health-services questions that become possible after a defensible discharge cohort has been constructed.";


    p "Interpretation remains intentionally descriptive. The data represent 2019 Q1 rather than a full year, the analytical unit is a discharge rather than a person, charges are not costs or payments, and no causal comparisons between payer or hospital groups are attempted.";

run;


/*==============================================================================
END OF SECTION 9
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 10. AMI PHENOTYPE PORTABILITY ACROSS CODING SYSTEMS
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — WHY PHENOTYPE PORTABILITY MATTERS
------------------------------------------------------------------------------*/

proc odstext;

    p "10. AMI Phenotype Portability Across Coding Systems"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "Administrative healthcare research frequently spans databases and calendar periods that use different clinical coding systems. A clinical phenotype therefore cannot always be transferred by copying the same diagnosis code from one source to another.";


    p "This project demonstrates phenotype portability using acute myocardial infarction. In the 2008-2010 Medicare inpatient data, AMI is operationalized using principal ICD-9-CM diagnosis 410.x. In the 2019 Q1 Texas THCIC inpatient data, the same clinical concept is operationalized using principal ICD-10-CM diagnosis I21.x.";


    p "The purpose of this comparison is methodological. The resulting record counts are not directly comparable measures of AMI frequency because the two data sources represent different populations, observation periods, database structures, coding eras, and analytical units.";

run;


/*==============================================================================
10A. CREATE THE PHENOTYPE-PORTABILITY TABLE
==============================================================================*/

/*
This preserves the logic from the successfully completed project.

Row 1:
Medicare DE-SynPUF inpatient
2008-2010
ICD-9-CM
Principal diagnosis 410.x

Row 2:
Texas THCIC inpatient
2019 Q1
ICD-10-CM
Principal diagnosis I21.x

AMI_RECORDS is simply the number of qualifying records in each already
constructed AMI cohort.

The table demonstrates phenotype translation rather than numerical
comparability between databases.
*/

proc sql;

    create table anal.phenotype_portability as


    select

        "Medicare DE-SynPUF inpatient"
            as data_source
            length=40,


        "2008-2010"
            as period
            length=15,


        "ICD-9-CM"
            as coding_system
            length=15,


        "Principal diagnosis 410.x"
            as ami_definition
            length=50,


        count(*)
            as ami_records


    from anal.ami_claims


    union all


    select

        "Texas THCIC inpatient",

        "2019 Q1",

        "ICD-10-CM",

        "Principal diagnosis I21.x",

        count(*)


    from anal.thcic_ami;

quit;


/*==============================================================================
10B. DISPLAY THE PORTABILITY TABLE
==============================================================================*/

proc print
    data=anal.phenotype_portability
    noobs
    label;


    var

        data_source

        period

        coding_system

        ami_definition

        ami_records;


    label

        data_source="Data source"

        period="Period"

        coding_system="Coding system"

        ami_definition="AMI phenotype"

        ami_records="Qualifying records";


    format

        ami_records
        comma12.;


    title
    "AMI Phenotype Portability Across Two Administrative Data Systems";

run;


title;


/*==============================================================================
10C. PHENOTYPE-PORTABILITY QUALITY CONTROL
==============================================================================*/

/*
The table should contain exactly two rows:

1 Medicare phenotype
1 Texas phenotype

This check also confirms that both record counts are greater than zero.

Short SAS aliases are deliberately used to remain within SAS naming limits.
*/

proc sql;

    title
    "AMI Phenotype Portability QC";


    select

        count(*)
            as n_rows
            label="Number of Portability Rows",


        sum
        (
            ami_records > 0
        )
            as n_nonzero
            label="Rows With Nonzero AMI Counts",


        sum
        (
            ami_records
        )
            as total_recs
            label="Combined Records Across Both Sources"
            format=comma12.

    from anal.phenotype_portability;

quit;


title;


/*==============================================================================
10D. VERIFY PORTABILITY COUNTS AGAINST THE SOURCE ANALYTIC COHORTS
==============================================================================*/

/*
This is an additional reproducibility check.

The values in the portability table should exactly match the number of
records in:

ANAL.AMI_CLAIMS
and
ANAL.THCIC_AMI

No data are altered.
*/

proc sql;

    title
    "AMI Portability Source-Count QC";


    select

        count(*)
            as cms_ami
            label="Medicare AMI Records"
            format=comma12.

    from anal.ami_claims;


    select

        count(*)
            as tx_ami
            label="Texas AMI Records"
            format=comma12.

    from anal.thcic_ami;

quit;


title;


/*==============================================================================
10E. CAPTURE PORTABILITY RESULTS FOR THE HTML REPORT
==============================================================================*/

/*
Initialize values first so unresolved macro variables cannot appear in the
report if a row were unexpectedly absent.
*/

%let PORT_CMS_N=Not observed;
%let PORT_TX_N=Not observed;


/* Medicare */

proc sql noprint;

    select

        strip
        (
            put
            (
                ami_records,
                comma20.
            )
        )

    into

        :PORT_CMS_N trimmed

    from anal.phenotype_portability

    where data_source=
        "Medicare DE-SynPUF inpatient";

quit;


/* Texas */

proc sql noprint;

    select

        strip
        (
            put
            (
                ami_records,
                comma20.
            )
        )

    into

        :PORT_TX_N trimmed

    from anal.phenotype_portability

    where data_source=
        "Texas THCIC inpatient";

quit;


/*==============================================================================
10F. WRITE PORTABILITY RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put AMI PHENOTYPE PORTABILITY;
%put MEDICARE DE-SYNPUF;
%put PERIOD        = 2008-2010;
%put CODING SYSTEM = ICD-9-CM;
%put DEFINITION    = PRINCIPAL DIAGNOSIS 410.X;
%put AMI RECORDS   = &PORT_CMS_N;
%put --------------------------------------------------------------------------;
%put TEXAS THCIC;
%put PERIOD        = 2019 Q1;
%put CODING SYSTEM = ICD-10-CM;
%put DEFINITION    = PRINCIPAL DIAGNOSIS I21.X;
%put AMI RECORDS   = &PORT_TX_N;
%put ==========================================================================;


/*==============================================================================
10G. INSERT RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Phenotype-portability results"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "In the Medicare DE-SynPUF inpatient data, the principal ICD-9-CM 410.x phenotype identified &PORT_CMS_N qualifying AMI records during 2008-2010.";


    p "In the Texas THCIC inpatient data, the corresponding principal ICD-10-CM I21.x phenotype identified &PORT_TX_N qualifying AMI discharges during 2019 Q1.";


    p "These counts should not be interpreted as evidence that AMI was more or less common in one dataset than the other. The Medicare and Texas sources differ in population coverage, time period, coding system, observation duration, analytical unit, and data-generating process.";


    p "Instead, the comparison demonstrates that a stable clinical concept can require different operational code definitions when implemented across databases and coding eras.";

run;


/*==============================================================================
10H. FINAL INTERPRETATION
==============================================================================*/

proc odstext;


    p "Interpretation"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "Phenotype portability is a central challenge in longitudinal and multi-database real-world evidence research. Researchers must preserve the clinical meaning of a condition while adapting its computable definition to the coding environment available in each data source.";


    p "For acute myocardial infarction, the project operationalizes the same underlying clinical concept using principal ICD-9-CM diagnosis 410.x in the historical Medicare environment and principal ICD-10-CM diagnosis I21.x in the later Texas environment.";


    p "The exercise also illustrates why harmonization does not imply direct numerical comparability. A harmonized phenotype can improve conceptual consistency across datasets without making the populations, denominators, follow-up periods, or resulting counts equivalent.";


    p "In a larger multi-database RWE study, this same principle would extend beyond diagnosis coding to enrollment definitions, procedure codes, medication coding systems, outcome windows, covariate definitions, and database-specific data-quality rules.";

run;


/*==============================================================================
END OF SECTION 10
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 11. EXPORT AGGREGATE PORTFOLIO TABLES
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — PUBLIC OUTPUT STRATEGY
------------------------------------------------------------------------------*/

proc odstext;

    p "11. Exporting the Reproducible Portfolio Outputs"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The analytical datasets created throughout Claims to Cohorts contain considerably more detail than is necessary for a public portfolio. The GitHub-facing output is therefore restricted to aggregate tables and publication-ready figures rather than row-level administrative healthcare records.";


    p "Fourteen aggregate CSV files are exported from the final SAS analytical datasets. These tables correspond directly to the results presented in the report and provide machine-readable versions of the dataset inventory, beneficiary denominators, AMI and stroke results, cervical-screening summaries, pharmacy outputs, Texas AMI summaries, and phenotype-portability table.";


    p "No row-level Texas THCIC discharge data are exported for public repository use. The public-facing workflow separates reproducible analytical code and aggregate results from source-level healthcare records.";

run;


/*==============================================================================
11A. EXPORT SOURCE-DATA INVENTORY
==============================================================================*/

proc export
    data=anal.dataset_inventory
    outfile="&TABDIR/dataset_inventory.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11B. EXPORT MEDICARE BENEFICIARY-YEAR ELIGIBILITY
==============================================================================*/

proc export
    data=anal.member_eligibility_year
    outfile="&TABDIR/member_eligibility_by_year.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11C. EXPORT AMI RESULTS
==============================================================================*/

proc export
    data=anal.ami_rate_year
    outfile="&TABDIR/ami_rate_by_year.csv"
    dbms=csv
    replace;
run;


proc export
    data=anal.ami_treatment_los
    outfile="&TABDIR/ami_treatment_los.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11D. EXPORT STROKE RESULTS
==============================================================================*/

proc export
    data=anal.stroke_rate_year
    outfile="&TABDIR/stroke_rate_by_year.csv"
    dbms=csv
    replace;
run;


proc export
    data=anal.stroke_treatment_los
    outfile="&TABDIR/stroke_treatment_los.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11E. EXPORT CERVICAL-SCREENING RESULTS
==============================================================================*/

proc export
    data=anal.cervical_rate_year
    outfile="&TABDIR/cervical_screening_by_year.csv"
    dbms=csv
    replace;
run;


proc export
    data=anal.cervical_rate_race
    outfile="&TABDIR/cervical_screening_by_race.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11F. EXPORT PHARMACY RESULTS
==============================================================================*/

proc export
    data=anal.bupropion_monthly
    outfile="&TABDIR/bupropion_monthly_fills.csv"
    dbms=csv
    replace;
run;


proc export
    data=anal.bupropion_crosswalk
    outfile="&TABDIR/bupropion_code_crosswalk.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11G. EXPORT TEXAS THCIC AGGREGATE RESULTS
==============================================================================*/

/*
Only aggregate THCIC tables are exported.

ANAL.THCIC_CORE and ANAL.THCIC_AMI are NOT exported to CSV here.
*/

proc export
    data=anal.thcic_ami_payer
    outfile="&TABDIR/thcic_ami_payer_distribution.csv"
    dbms=csv
    replace;
run;


proc export
    data=anal.thcic_ami_admission
    outfile="&TABDIR/thcic_ami_admission_distribution.csv"
    dbms=csv
    replace;
run;


proc export
    data=anal.thcic_ami_payer_resource
    outfile="&TABDIR/thcic_ami_resource_use_by_payer.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11H. EXPORT AMI PHENOTYPE-PORTABILITY TABLE
==============================================================================*/

proc export
    data=anal.phenotype_portability
    outfile="&TABDIR/ami_phenotype_portability.csv"
    dbms=csv
    replace;
run;


/*==============================================================================
11I. CREATE AN EXPORT MANIFEST
==============================================================================*/

/*
The manifest documents:

- the expected CSV filename;
- the SAS dataset from which it was exported;
- the full output path.

This becomes part of the reproducibility record.
*/

data anal.export_manifest;

    length
        file_name $60
        source_data $50
        full_path $300;


    infile datalines
        dlm="|"
        dsd
        truncover;


    input
        export_order
        file_name :$60.
        source_data :$50.;


    full_path=
        cats
        (
            "&TABDIR/",
            file_name
        );


    datalines;
1|dataset_inventory.csv|ANAL.DATASET_INVENTORY
2|member_eligibility_by_year.csv|ANAL.MEMBER_ELIGIBILITY_YEAR
3|ami_rate_by_year.csv|ANAL.AMI_RATE_YEAR
4|ami_treatment_los.csv|ANAL.AMI_TREATMENT_LOS
5|stroke_rate_by_year.csv|ANAL.STROKE_RATE_YEAR
6|stroke_treatment_los.csv|ANAL.STROKE_TREATMENT_LOS
7|cervical_screening_by_year.csv|ANAL.CERVICAL_RATE_YEAR
8|cervical_screening_by_race.csv|ANAL.CERVICAL_RATE_RACE
9|bupropion_monthly_fills.csv|ANAL.BUPROPION_MONTHLY
10|bupropion_code_crosswalk.csv|ANAL.BUPROPION_CROSSWALK
11|thcic_ami_payer_distribution.csv|ANAL.THCIC_AMI_PAYER
12|thcic_ami_admission_distribution.csv|ANAL.THCIC_AMI_ADMISSION
13|thcic_ami_resource_use_by_payer.csv|ANAL.THCIC_AMI_PAYER_RESOURCE
14|ami_phenotype_portability.csv|ANAL.PHENOTYPE_PORTABILITY
;

run;


/*==============================================================================
11J. VERIFY THAT THE EXPECTED CSV FILES EXIST
==============================================================================*/

/*
FILEEXIST checks whether the external file exists at the specified path.

This does not read or modify the CSV.

It simply returns:

1 = file exists
0 = file not found
*/

data anal.export_audit;

    set anal.export_manifest;


    file_exists=
        fileexist
        (
            full_path
        );


    length export_status $12;


    if file_exists=1

        then export_status=
        "Created";


    else

        export_status=
        "Missing";

run;


/*==============================================================================
11K. DISPLAY THE EXPORT AUDIT
==============================================================================*/

proc print
    data=anal.export_audit
    noobs
    label;


    var

        export_order

        file_name

        source_data

        export_status;


    label

        export_order="Order"

        file_name="CSV File"

        source_data="Source SAS Dataset"

        export_status="Status";


    title
    "Claims to Cohorts: Aggregate CSV Export Audit";

run;


title;


/*==============================================================================
11L. CAPTURE EXPORT-AUDIT RESULTS
==============================================================================*/

proc sql noprint;


    select

        count(*),

        sum
        (
            file_exists
        ),

        sum
        (
            file_exists=0
        )

    into

        :EXPORT_EXPECTED trimmed,

        :EXPORT_CREATED trimmed,

        :EXPORT_MISSING trimmed

    from anal.export_audit;

quit;


/*==============================================================================
11M. WRITE EXPORT RESULTS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put CLAIMS TO COHORTS AGGREGATE EXPORT AUDIT;
%put EXPECTED CSV FILES = &EXPORT_EXPECTED;
%put CREATED CSV FILES  = &EXPORT_CREATED;
%put MISSING CSV FILES  = &EXPORT_MISSING;
%put OUTPUT DIRECTORY   = &TABDIR;
%put ==========================================================================;


/*==============================================================================
11N. INSERT EXPORT RESULTS INTO THE HTML REPORT
==============================================================================*/

proc odstext;


    p "Export audit"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The master program expected &EXPORT_EXPECTED aggregate CSV outputs. The post-export audit identified &EXPORT_CREATED files in the designated tables directory and &EXPORT_MISSING expected files that were not found.";


    p "The exported tables are derived directly from the analytical datasets created during the same SAS execution. This design reduces the risk of manually copying numerical results from one analysis version into documentation produced from another.";


    p "The aggregate CSV files and standalone PNG figures will form the results layer of the GitHub repository, while the complete SAS master program provides the executable analytical workflow.";

run;


/*==============================================================================
11O. DATA-GOVERNANCE NOTE
==============================================================================*/

proc odstext;


    p "Public-repository data boundary"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "The public repository is intended to contain analytical code, documentation, aggregate tables, and figures. Row-level Texas THCIC discharge records are not included among the public CSV exports.";


    p "Similarly, the repository does not need to contain large SAS analytic datasets simply because they were generated during execution. Reproducibility is supported by documenting the required source files, folder structure, cohort definitions, and executable SAS program while restricting public outputs to the level appropriate for portfolio dissemination.";

run;


/*==============================================================================
END OF SECTION 11
==============================================================================*/


title;
footnote;



/*==============================================================================
SECTION 12. FINAL REPRODUCIBILITY AND PROJECT-COMPLETION AUDIT
==============================================================================*/


title;
footnote;


/*------------------------------------------------------------------------------
REPORT NARRATIVE — PURPOSE OF THE FINAL AUDIT
------------------------------------------------------------------------------*/

proc odstext;

    p "12. Reproducibility and Final Project Audit"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "The final stage of Claims to Cohorts verifies that the analytical datasets, figures, aggregate CSV tables, and key numerical results expected from the project were produced during the current SAS execution.";


    p "This audit is designed to reduce the risk of publishing results generated from different versions of the analysis. The final report therefore records the execution environment, verifies the core analytical outputs, compares selected headline results with the validated project benchmarks, and confirms that the expected public-facing tables and figures exist.";


    p "A successful audit does not independently validate every clinical assumption in the project. Instead, it confirms that the predefined analytical workflow executed consistently and generated the expected reproducibility artifacts.";

run;


/*==============================================================================
12A. DISPLAY SAS EXECUTION METADATA
==============================================================================*/

/*
ANAL.RUN_METADATA was created in Section 0.

It records:

- project name
- project version
- SAS version
- operating environment
- execution date/time

The project path itself is deliberately not printed into the public HTML
report so that a personal SAS OnDemand user identifier is not exposed.
*/

title
"Claims to Cohorts: Reproducibility Metadata";


proc print
    data=anal.run_metadata
    noobs
    label;


    var

        project_name

        project_version

        run_datetime

        sas_version

        operating_environment;


    label

        project_name=
        "Project"

        project_version=
        "Version"

        run_datetime=
        "Run Date and Time"

        sas_version=
        "SAS Version"

        operating_environment=
        "Operating Environment";

run;


title;


/*==============================================================================
12B. DEFINE THE CORE ANALYTICAL DATASETS EXPECTED FROM THE MASTER PROGRAM
==============================================================================*/

/*
This manifest contains the major SAS datasets that should exist after the
complete analysis has run.

It is not necessary to list every temporary or QC dataset.

The purpose is to verify the analytical spine of the project.
*/

data anal.dataset_manifest;

    length
        ds_name $50;


    infile datalines
        dlm="|"
        dsd
        truncover;


    input
        audit_order
        ds_name :$50.;


    datalines;
1|RUN_METADATA
2|DATASET_INVENTORY
3|MEMBER_YEAR
4|MEMBER_ELIGIBILITY_YEAR
5|AMI_CLAIMS
6|AMI_TREATMENT_LOS
7|AMI_RATE_YEAR
8|STROKE_CLAIMS
9|STROKE_TREATMENT_LOS
10|STROKE_RATE_YEAR
11|CERVICAL_MEMBER_YEAR
12|CERVICAL_RATE_YEAR
13|CERVICAL_RATE_RACE
14|BUPROPION_MEMBER
15|BUPROPION_MONTHLY
16|BUPROPION_REFILL_INTERVALS
17|BUPROPION_CROSSWALK
18|THCIC_AMI
19|THCIC_AMI_PAYER
20|THCIC_AMI_ADMISSION
21|THCIC_AMI_PAYER_RESOURCE
22|PHENOTYPE_PORTABILITY
23|EXPORT_MANIFEST
24|EXPORT_AUDIT
;

run;


/*==============================================================================
12C. VERIFY THAT THE CORE ANALYTICAL DATASETS EXIST
==============================================================================*/

/*
EXIST() returns:

1 = SAS dataset exists
0 = dataset does not exist
*/

data anal.dataset_audit;

    set anal.dataset_manifest;


    length
        ds_ref $60
        ds_status $12;


    ds_ref=
        cats
        (
            "ANAL.",
            ds_name
        );


    ds_exists=
        exist
        (
            ds_ref
        );


    if ds_exists=1

        then ds_status=
        "Created";


    else

        ds_status=
        "Missing";

run;


/*==============================================================================
12D. SUMMARIZE THE ANALYTICAL-DATASET AUDIT
==============================================================================*/

proc sql noprint;

    select

        count(*),

        sum
        (
            ds_exists
        ),

        sum
        (
            ds_exists=0
        )

    into

        :DS_EXPECTED trimmed,

        :DS_CREATED trimmed,

        :DS_MISSING trimmed

    from anal.dataset_audit;

quit;


/*==============================================================================
12E. DEFINE THE 13 EXPECTED FINAL FIGURES
==============================================================================*/

data anal.figure_manifest;

    length
        file_name $60
        full_path $300;


    infile datalines
        dlm="|"
        dsd
        truncover;


    input
        fig_order
        file_name :$60.;


    full_path=
        cats
        (
            "&FIGDIR/",
            file_name
        );


    datalines;
1|01_dataset_inventory.png
2|02_member_eligibility.png
3|03_ami_rate_by_year.png
4|04_ami_los_by_treatment.png
5|05_stroke_rate_by_year.png
6|06_stroke_los_by_treatment.png
7|07_cervical_screening_by_year.png
8|08_cervical_screening_race_2010.png
9|09_bupropion_monthly_fills.png
10|10_bupropion_refill_intervals.png
11|11_thcic_ami_payer_mix.png
12|12_thcic_ami_admission_type.png
13|13_thcic_ami_median_charges.png
;

run;


/*==============================================================================
12F. VERIFY THAT ALL 13 FIGURES EXIST
==============================================================================*/

data anal.figure_audit;

    set anal.figure_manifest;


    length
        fig_status $12;


    file_exists=
        fileexist
        (
            full_path
        );


    if file_exists=1

        then fig_status=
        "Created";


    else

        fig_status=
        "Missing";

run;


/* Summarize figure audit */

proc sql noprint;

    select

        count(*),

        sum
        (
            file_exists
        ),

        sum
        (
            file_exists=0
        )

    into

        :FIG_EXPECTED trimmed,

        :FIG_CREATED trimmed,

        :FIG_MISSING trimmed

    from anal.figure_audit;

quit;


/*==============================================================================
12G. RECHECK THE 14 AGGREGATE CSV EXPORTS
==============================================================================*/

/*
Section 11 already created ANAL.EXPORT_AUDIT.

Here we summarize it again for the final project-level audit.
*/

proc sql noprint;

    select

        count(*),

        sum
        (
            file_exists
        ),

        sum
        (
            file_exists=0
        )

    into

        :CSV_EXPECTED trimmed,

        :CSV_CREATED trimmed,

        :CSV_MISSING trimmed

    from anal.export_audit;

quit;


/*==============================================================================
12H. RECALCULATE THE KEY HEADLINE RESULTS
==============================================================================*/

/*
These values are recalculated directly from the final analytical datasets.

They will be compared with the validated project benchmarks.

Numeric macro variables are intentionally captured WITHOUT comma formatting
so that SAS can compare them numerically.
*/


/* Total source records */

proc sql noprint;

    select
        sum(nobs)

    into
        :FINAL_SOURCE_N trimmed

    from anal.dataset_inventory;

quit;


/* Medicare Part A and Part B beneficiary-years */

proc sql noprint;

    select

        sum
        (
            part_a_ffs_members
        ),

        sum
        (
            part_b_ffs_members
        )

    into

        :FINAL_PARTA_N trimmed,

        :FINAL_PARTB_N trimmed

    from anal.member_eligibility_year;

quit;


/* Distinct AMI claim IDs */

proc sql noprint;

    select

        count
        (
            distinct CLM_ID
        )

    into

        :FINAL_AMI_N trimmed

    from anal.ami_claims;

quit;


/* Distinct stroke claim IDs */

proc sql noprint;

    select

        count
        (
            distinct CLM_ID
        )

    into

        :FINAL_STROKE_N trimmed

    from anal.stroke_claims;

quit;


/* Cervical-screening eligible beneficiary-years */

proc sql noprint;

    select

        count(*)

    into

        :FINAL_CERV_N trimmed

    from anal.cervical_member_year;

quit;


/* Bupropion users and fills */

proc sql noprint;

    select

        count
        (
            distinct MemberID
        ),

        count(*)

    into

        :FINAL_BUP_USERS trimmed,

        :FINAL_BUP_FILLS trimmed

    from anal.pharmacy_clean

    where bupropion=1;

quit;


/* Texas AMI discharges */

proc sql noprint;

    select

        count(*)

    into

        :FINAL_TX_AMI trimmed

    from anal.thcic_ami;

quit;


/*==============================================================================
12I. CREATE THE KEY-RESULT INTEGRITY AUDIT
==============================================================================*/

/*
These expected values correspond to the validated final project results.

If the source files or analytic logic change in a future project version,
the expected values should be updated deliberately rather than silently.

MATCH_FLAG:

1 = observed result matches expected result
0 = mismatch requiring review
*/

data anal.result_audit;

    length
        metric $55;


    metric=
        "Total source records";

    expected_value=
        1813866;

    observed_value=
        &FINAL_SOURCE_N;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Part A FFS beneficiary-years";

    expected_value=
        221923;

    observed_value=
        &FINAL_PARTA_N;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Part B FFS beneficiary-years";

    expected_value=
        212795;

    observed_value=
        &FINAL_PARTB_N;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Distinct Medicare AMI claim IDs";

    expected_value=
        1639;

    observed_value=
        &FINAL_AMI_N;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Distinct Medicare stroke claim IDs";

    expected_value=
        1404;

    observed_value=
        &FINAL_STROKE_N;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Cervical-screening eligible beneficiary-years";

    expected_value=
        18839;

    observed_value=
        &FINAL_CERV_N;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Unique bupropion users";

    expected_value=
        1290;

    observed_value=
        &FINAL_BUP_USERS;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Qualifying bupropion fills";

    expected_value=
        11135;

    observed_value=
        &FINAL_BUP_FILLS;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;



    metric=
        "Texas THCIC AMI discharges";

    expected_value=
        13168;

    observed_value=
        &FINAL_TX_AMI;

    match_flag=
        (
            expected_value=
            observed_value
        );

    output;


    format

        expected_value
        observed_value
        comma14.;

run;


/*==============================================================================
12J. SUMMARIZE THE RESULT-INTEGRITY AUDIT
==============================================================================*/

proc sql noprint;

    select

        count(*),

        sum
        (
            match_flag
        ),

        sum
        (
            match_flag=0
        )

    into

        :RES_EXPECTED trimmed,

        :RES_MATCHED trimmed,

        :RES_MISMATCH trimmed

    from anal.result_audit;

quit;


/*==============================================================================
12K. CREATE ONE COMPACT FINAL AUDIT SUMMARY TABLE
==============================================================================*/

data anal.final_audit_summary;

    length
        audit_area $35;


    audit_area=
        "Core analytical datasets";

    expected=
        &DS_EXPECTED;

    found=
        &DS_CREATED;

    missing=
        &DS_MISSING;

    output;



    audit_area=
        "PNG figures";

    expected=
        &FIG_EXPECTED;

    found=
        &FIG_CREATED;

    missing=
        &FIG_MISSING;

    output;



    audit_area=
        "Aggregate CSV exports";

    expected=
        &CSV_EXPECTED;

    found=
        &CSV_CREATED;

    missing=
        &CSV_MISSING;

    output;



    audit_area=
        "Validated key-result checks";

    expected=
        &RES_EXPECTED;

    found=
        &RES_MATCHED;

    missing=
        &RES_MISMATCH;

    output;

run;


/*==============================================================================
12L. DETERMINE OVERALL PROJECT STATUS
==============================================================================*/

/*
PASS requires:

- every expected core analytical dataset;
- every expected figure;
- every expected aggregate CSV;
- every validated key result.

Otherwise the status becomes REVIEW REQUIRED.
*/

data _null_;

    length
        status $20;


    if &DS_MISSING=0
       and
       &FIG_MISSING=0
       and
       &CSV_MISSING=0
       and
       &RES_MISMATCH=0

        then status=
        "PASS";


    else

        status=
        "REVIEW REQUIRED";


    call symputx
    (
        "FINAL_STATUS",
        status
    );

run;


/*==============================================================================
12M. DISPLAY THE KEY-RESULT INTEGRITY AUDIT
==============================================================================*/

proc print
    data=anal.result_audit
    noobs
    label;


    var

        metric

        expected_value

        observed_value

        match_flag;


    label

        metric=
        "Validated Result"

        expected_value=
        "Expected"

        observed_value=
        "Observed"

        match_flag=
        "Match";


    title
    "Claims to Cohorts: Key-Result Integrity Audit";

run;


title;


/*==============================================================================
12N. DISPLAY THE FINAL OUTPUT AUDIT
==============================================================================*/

proc print
    data=anal.final_audit_summary
    noobs
    label;


    var

        audit_area

        expected

        found

        missing;


    label

        audit_area=
        "Audit Area"

        expected=
        "Expected"

        found=
        "Found / Matched"

        missing=
        "Missing / Mismatched";


    title
    "Claims to Cohorts: Final Reproducibility Audit";

run;


title;


/*==============================================================================
12O. DISPLAY THE ANALYTIC LIBRARY
==============================================================================*/

/*
This preserves the final PROC DATASETS inspection from the original successful
program.

It provides a final inventory of permanent analytical SAS datasets.
*/

title
"Claims to Cohorts: Completed Analytic Datasets";


proc datasets
    library=anal;

run;

quit;


title;


/*==============================================================================
12P. WRITE FINAL COMPLETION STATUS TO THE SAS LOG
==============================================================================*/

%put ==========================================================================;
%put CLAIMS TO COHORTS FINAL PROJECT AUDIT;
%put PROJECT VERSION             = &PROJECT_VERSION;
%put --------------------------------------------------------------------------;
%put CORE DATASETS EXPECTED      = &DS_EXPECTED;
%put CORE DATASETS CREATED       = &DS_CREATED;
%put CORE DATASETS MISSING       = &DS_MISSING;
%put --------------------------------------------------------------------------;
%put FIGURES EXPECTED            = &FIG_EXPECTED;
%put FIGURES CREATED             = &FIG_CREATED;
%put FIGURES MISSING             = &FIG_MISSING;
%put --------------------------------------------------------------------------;
%put CSV FILES EXPECTED          = &CSV_EXPECTED;
%put CSV FILES CREATED           = &CSV_CREATED;
%put CSV FILES MISSING           = &CSV_MISSING;
%put --------------------------------------------------------------------------;
%put KEY RESULTS CHECKED         = &RES_EXPECTED;
%put KEY RESULTS MATCHED         = &RES_MATCHED;
%put KEY RESULT MISMATCHES       = &RES_MISMATCH;
%put --------------------------------------------------------------------------;
%put FINAL STATUS                = &FINAL_STATUS;
%put ==========================================================================;


/*==============================================================================
12Q. FINAL HTML REPORT INTERPRETATION
==============================================================================*/

proc odstext;


    p "Final reproducibility status"
        /
        style=
        [
            font_size=14pt
            font_weight=bold
        ];


    p "Final project audit status: &FINAL_STATUS."
        /
        style=
        [
            font_size=13pt
            font_weight=bold
        ];


    p "The final audit expected &DS_EXPECTED core analytical SAS datasets and identified &DS_CREATED. It expected &FIG_EXPECTED publication-ready PNG figures and identified &FIG_CREATED. It expected &CSV_EXPECTED aggregate CSV tables and identified &CSV_CREATED.";


    p "The program also evaluated &RES_EXPECTED validated headline results against the accepted project benchmarks. &RES_MATCHED matched the expected values, while &RES_MISMATCH required review.";


    p "If the final status is PASS, the analytical datasets, key numerical results, figures, and aggregate tables required for the portfolio were reproduced successfully during the current master-program execution. If the status is REVIEW REQUIRED, the corresponding audit datasets should be inspected before any files are published.";


    p "The project uses one authoritative SAS master program so that data inventory, quality control, cohort construction, clinical phenotyping, aggregation, visualization, export, and final validation occur within a traceable analytical workflow.";

run;


/*==============================================================================
12R. FINAL PROJECT CONCLUSION
==============================================================================*/

proc odstext;


    p "Conclusion"
        /
        style=
        [
            font_size=18pt
            font_weight=bold
        ];


    p "Claims to Cohorts demonstrates how heterogeneous administrative healthcare records can be transformed into reproducible analytic cohorts through explicit decisions about data structure, eligibility, observational unit, code-based phenotypes, aggregation, linkage, and longitudinal exposure construction.";


    p "Across beneficiary enrollment, inpatient claims, professional claims, pharmacy dispensing records, and real-world hospital discharge data, the project shows that identifying diagnosis or procedure codes is only one component of claims analytics. Defensible real-world evidence also requires defining who is observable, what constitutes an event, how repeated records are handled, which denominator answers the research question, and how clinical concepts are translated across coding environments.";


    p "The project therefore emphasizes a reusable analytical sequence: source data, structural audit, eligibility, phenotype construction, aggregation, linkage, analytic cohort, descriptive measure, reproducible output, and final validation.";


    p "Raw claims do not become real-world evidence until the analyst defines the cohort correctly."
        /
        style=
        [
            font_size=13pt
            font_weight=bold
        ];

run;


/*==============================================================================
12S. CLEAN REPORT TITLES AND FOOTNOTES
==============================================================================*/

title;
footnote;


/*==============================================================================
12T. CLOSE THE HTML REPORT
==============================================================================*/

/*
This line is essential.

Section 0 opened CLAIMS_TO_COHORTS_REPORT.HTML.

The report remains open throughout Sections 1-12 so that narrative, tables,
and figures are written into one continuous HTML document.

ODS HTML5 CLOSE finalizes the HTML file.
*/

ods html5 close;


/* Turn off graphics after all figures have been generated */

ods graphics off;


/*==============================================================================
12U. VERIFY THAT THE FINAL HTML FILE EXISTS
==============================================================================*/

/*
This check occurs AFTER ODS HTML5 CLOSE.

Because the report is now closed, the result is written to the SAS Log rather
than inserted into the HTML itself.
*/

data _null_;

    length
        report_path $300;


    report_path=
        cats
        (
            "&REPORTDIR/",
            "Claims_to_Cohorts_Report.html"
        );


    report_exists=
        fileexist
        (
            report_path
        );


    call symputx
    (
        "HTML_EXISTS",
        report_exists
    );

run;


/*==============================================================================
12V. FINAL SAS LOG MESSAGE
==============================================================================*/

%put ==========================================================================;
%put CLAIMS TO COHORTS ANALYSIS COMPLETED.;
%put PROJECT VERSION      = &PROJECT_VERSION;
%put FINAL AUDIT STATUS   = &FINAL_STATUS;
%put HTML REPORT EXISTS   = &HTML_EXISTS;
%put --------------------------------------------------------------------------;
%put ANALYTIC DATASETS    = &ANALDIR;
%put FIGURES              = &FIGDIR;
%put TABLES               = &TABDIR;
%put REPORTS              = &REPORTDIR;
%put ==========================================================================;


/*==============================================================================
END OF CLAIMS TO COHORTS MASTER ANALYSIS
==============================================================================*/