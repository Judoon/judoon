#!/usr/bin/env perl

use utf8;

use Test::Roo;
use lib 't/lib';
with 'Judoon::Role::ScrubHTML';

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

test 'scrub_html_string' => sub {
    my ($self) = @_;

    is $self->scrub_html_string('hey'), 'hey', 'basic test';
    is $self->scrub_html_string('hey &amp; hi'), 'hey &amp; hi', 'html entities not decoded';
    is $self->scrub_html_string('<em>hey</em>'), '<em>hey</em>', 'some html allowed';
    is $self->scrub_html_string('<script>hey</script>'), '', 'scary html rejected';
    is $self->scrub_html_string('<p>hey</p>'), 'hey', 'less scary html munged';
    is $self->scrub_html_string('&lt;script&gt;hey&lt;/script&gt;'), '&lt;script&gt;hey&lt;/script&gt;', 'entities => tags not converted';
    is $self->scrub_html_string("<p><strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.</p>"),
        "<strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.",
            'html_string strips <p> tags';

};

test 'scrub_html_block' => sub {
    my ($self) = @_;
    fail("not yet implemented");
};


run_me();
done_testing();

__END__

    article.abstract         "<p>Cortactin binds to Arp2/3 and filamentous actin to facilitate ECM secretion and thereby promote cell migration.</p>",
    article.author           "Katrin Legg",
    article.body             "<p>Cortactin is present in lamellipodia, functions as a cofactor for Arp2/3 activation and can stabilize actin branches, making it seemingly well placed to promote cell motility by regulating leading edge lamellipodial dynamics. However, cortactin also regulates membrane trafficking and adhesion dynamics; furthermore, cells that lack a lamellipodium have been reported to migrate well, so the current mechanisms proposed for cortactin’s role in cell migration cannot fully explain the existing data. Now, however, Alissa Weaver’s group reports that cortactin regulates cell motility by promoting the secretion of extracellular matrix (ECM), a finding that seems to reconcile the conflicting data.</p>
<p>Having previously observed impaired cell motility, lamellipodial stability and adhesion assembly in cortactin-knockdown cells, Weaver’s group hypothesized that defective ECM secretion or altered integrin trafficking might be the cause. They initially found that plating cortactin-knockdown cells on exogenous ECM rescued the defects. Notably, high concentrations of fibronectin also prevented an increase in the internalization of β1 integrin, implying that cortactin-knockdown cells might be defective in secreting ECM (causing excess unengaged integrins to be endocytosed).</p>
<p>By coating plates with cell-free ECM derived from control or cortactin-knockdown cells, the authors then showed that only autocrine-generated ECM from cortactin-expressing cells rescued the motility defect of cortactin-deficient cells. Immunostaining revealed that less fibronectin was deposited in the ECM of cortactin-knockdown cells; instead, it accumulated in large perinuclear punctae, implying impaired exit from a secretory compartment. As a first step to identifying the compartment, the authors repeated their studies using fibronectin-depleted serum to establish the source of fibronectin in these cellular structures. The results indicated that, in the presence of cortactin, cells normally internalize and resecrete exogenous fibronectin, rather than synthesizing it. Indeed, pulse–chase experiments using biotinylated fibronectin confirmed that cortactin-knockdown cells secreted less internalized fibronectin.</p>
<p>Weaver’s group then used vesicular markers and live-cell imaging with labelled fibronectin to show that cortactin normally regulates a late endosomal/lysosomal secretory compartment that processes and deposits fibronectin at the basal surface. Knocking down the expression of synaptotagmin-7, a secretory lysosome fusion regulator, also resulted in decreased basal fibronectin deposition and motility, indicating that lysosomal secretion might be a general mechanism of migration regulation.</p>
<p>Finally, to establish a molecular mechanism for cortactin’s function in fibronectin secretion and cell migration, Weaver’s group used mutant-rescue studies to show that cortactin binding to Arp2/3 and actin filaments was essential. Its interaction with Src-homology-3 (SH3)-domain binding partners was dispensable, which is surprising, given that the SH3 domain binds most cortactin-binding partners, many of which are implicated in the regulation of vesicle trafficking.</p>
<p>The results of this study therefore indicate that cortactin, through its interactions with Arp2/3 and filamentous actin, facilitates the resecretion and deposition of internalized, processed fibronectin to promote cell migration. However, given its high affinity for these partners, cortactin is almost certain to also regulate actin dynamics elsewhere in the cell — for example, within lamellipodia. Although a primary role for cortactin in lamellipodia regulation was not important for cell motility in this study, Weaver’s group considers that regulation of lamellipodial actin dynamics by cortactin might still contribute to efficient cell migration, perhaps under different circumstances.</p>",
    article.figure           "present",
    article.legend           "<p>Cortactin controls resecretion of exogenous fibronectin at the cell–substrate interface, as revealed by live TIRF imaging of DyLight550-labelled fibronectin (FN). Control HT1080 fibrosarcoma cells (Sc; scrambled oligo) deposited fibronectin in linear streaks at the basal surface, thereby promoting cell migration, whereas cortactin-knockdown (KD) cells deposited markedly less fibronectin. Scale bar, 10 μm. Image courtesy of Dr Alissa M. Weaver, Vanderbilt University Medical Center, Nashville, TN, USA.</p>",
    article.title            "Cortactin helps to pave the way",
    month_id                 "jan12",
    publication.author       "Sung, B.H. <em>et al</em>.",
    publication.doi          "10.1016/j.cub.2011.06.065",
    publication.journal      "Curr. Biol.",
    publication.online_pub   "",
    publication.pages        "1460–1469",
    publication.title        "Cortactin controls cell motility and lamellipodial dynamics by regulating ECM secretion",
    publication.volume       21,
    publication.year         2011
    article.abstract         "<p>Cortactin binds to Arp2/3 and filamentous actin to facilitate ECM secretion and thereby promote cell migration.</p>",
    article.author           "Katrin Legg",
    article.body             "<p>Cortactin is present in lamellipodia, functions as a cofactor for Arp2/3 activation and can stabilize actin branches, making it seemingly well placed to promote cell motility by regulating leading edge lamellipodial dynamics. However, cortactin also regulates membrane trafficking and adhesion dynamics; furthermore, cells that lack a lamellipodium have been reported to migrate well, so the current mechanisms proposed for cortactin’s role in cell migration cannot fully explain the existing data. Now, however, Alissa Weaver’s group reports that cortactin regulates cell motility by promoting the secretion of extracellular matrix (ECM), a finding that seems to reconcile the conflicting data.</p>
<p>Having previously observed impaired cell motility, lamellipodial stability and adhesion assembly in cortactin-knockdown cells, Weaver’s group hypothesized that defective ECM secretion or altered integrin trafficking might be the cause. They initially found that plating cortactin-knockdown cells on exogenous ECM rescued the defects. Notably, high concentrations of fibronectin also prevented an increase in the internalization of β1 integrin, implying that cortactin-knockdown cells might be defective in secreting ECM (causing excess unengaged integrins to be endocytosed).</p>
<p>By coating plates with cell-free ECM derived from control or cortactin-knockdown cells, the authors then showed that only autocrine-generated ECM from cortactin-expressing cells rescued the motility defect of cortactin-deficient cells. Immunostaining revealed that less fibronectin was deposited in the ECM of cortactin-knockdown cells; instead, it accumulated in large perinuclear punctae, implying impaired exit from a secretory compartment. As a first step to identifying the compartment, the authors repeated their studies using fibronectin-depleted serum to establish the source of fibronectin in these cellular structures. The results indicated that, in the presence of cortactin, cells normally internalize and resecrete exogenous fibronectin, rather than synthesizing it. Indeed, pulse–chase experiments using biotinylated fibronectin confirmed that cortactin-knockdown cells secreted less internalized fibronectin.</p>
<p>Weaver’s group then used vesicular markers and live-cell imaging with labelled fibronectin to show that cortactin normally regulates a late endosomal/lysosomal secretory compartment that processes and deposits fibronectin at the basal surface. Knocking down the expression of synaptotagmin-7, a secretory lysosome fusion regulator, also resulted in decreased basal fibronectin deposition and motility, indicating that lysosomal secretion might be a general mechanism of migration regulation.</p>
<p>Finally, to establish a molecular mechanism for cortactin’s function in fibronectin secretion and cell migration, Weaver’s group used mutant-rescue studies to show that cortactin binding to Arp2/3 and actin filaments was essential. Its interaction with Src-homology-3 (SH3)-domain binding partners was dispensable, which is surprising, given that the SH3 domain binds most cortactin-binding partners, many of which are implicated in the regulation of vesicle trafficking.</p>
<p>The results of this study therefore indicate that cortactin, through its interactions with Arp2/3 and filamentous actin, facilitates the resecretion and deposition of internalized, processed fibronectin to promote cell migration. However, given its high affinity for these partners, cortactin is almost certain to also regulate actin dynamics elsewhere in the cell — for example, within lamellipodia. Although a primary role for cortactin in lamellipodia regulation was not important for cell motility in this study, Weaver’s group considers that regulation of lamellipodial actin dynamics by cortactin might still contribute to efficient cell migration, perhaps under different circumstances.</p>",
    article.figure           "present",
    article.legend           "<p>Cortactin controls resecretion of exogenous fibronectin at the cell–substrate interface, as revealed by live TIRF imaging of DyLight550-labelled fibronectin (FN). Control HT1080 fibrosarcoma cells (Sc; scrambled oligo) deposited fibronectin in linear streaks at the basal surface, thereby promoting cell migration, whereas cortactin-knockdown (KD) cells deposited markedly less fibronectin. Scale bar, 10 μm. Image courtesy of Dr Alissa M. Weaver, Vanderbilt University Medical Center, Nashville, TN, USA.</p>",
    article.title            "Cortactin helps to pave the way",
    month_id                 "jan12",
    publication.author       "Sung, B.H. <em>et al</em>.",
    publication.doi          "10.1016/j.cub.2011.06.065",
    publication.journal      "Curr. Biol.",
    publication.online_pub   "",
    publication.pages        "1460–1469",
    publication.title        "Cortactin controls cell motility and lamellipodial dynamics by regulating ECM secretion",
    publication.volume       21,
    publication.year         2011


<p>Cortactin is present in lamellipodia, functions as a cofactor for Arp2/3 activation and can stabilize actin branches, making it seemingly well placed to promote cell motility by regulating leading edge lamellipodial dynamics. However, cortactin also regulates membrane trafficking and adhesion dynamics; furthermore, cells that lack a lamellipodium have been reported to migrate well, so the current mechanisms proposed for cortactin\x{2019}s role in cell migration cannot fully explain the existing data. Now, however, Alissa Weaver\x{2019}s group reports that cortactin regulates cell motility by promoting the secretion of extracellular matrix (ECM), a finding that seems to reconcile the conflicting data.</p>\r\n<p>Having previously observed impaired cell motility, lamellipodial stability and adhesion assembly in cortactin-knockdown cells, Weaver\x{2019}s group hypothesized that defective ECM secretion or altered integrin trafficking might be the cause. They initially found that plating cortactin-knockdown cells on exogenous ECM rescued the defects. Notably, high concentrations of fibronectin also prevented an increase in the internalization of \x{3B2}1 integrin, implying that cortactin-knockdown cells might be defective in secreting ECM (causing excess unengaged integrins to be endocytosed).</p>\r\n<p>By coating plates with cell-free ECM derived from control or cortactin-knockdown cells, the authors then showed that only autocrine-generated ECM from cortactin-expressing cells rescued the motility defect of cortactin-deficient cells. Immunostaining revealed that less fibronectin was deposited in the ECM of cortactin-knockdown cells; instead, it accumulated in large perinuclear punctae, implying impaired exit from a secretory compartment. As a first step to identifying the compartment, the authors repeated their studies using fibronectin-depleted serum to establish the source of fibronectin in these cellular structures. The results indicated that, in the presence of cortactin, cells normally internalize and resecrete exogenous fibronectin, rather than synthesizing it. Indeed, pulse\x{2013}chase experiments using biotinylated fibronectin confirmed that cortactin-knockdown cells secreted less internalized fibronectin.</p>\r\n<p>Weaver\x{2019}s group then used vesicular markers and live-cell imaging with labelled fibronectin to show that cortactin normally regulates a late endosomal/lysosomal secretory compartment that processes and deposits fibronectin at the basal surface. Knocking down the expression of synaptotagmin-7, a secretory lysosome fusion regulator, also resulted in decreased basal fibronectin deposition and motility, indicating that lysosomal secretion might be a general mechanism of migration regulation.</p>\r\n<p>Finally, to establish a molecular mechanism for cortactin\x{2019}s function in fibronectin secretion and cell migration, Weaver\x{2019}s group used mutant-rescue studies to show that cortactin binding to Arp2/3 and actin filaments was essential. Its interaction with Src-homology-3 (SH3)-domain binding partners was dispensable, which is surprising, given that the SH3 domain binds most cortactin-binding partners, many of which are implicated in the regulation of vesicle trafficking.</p>\r\n<p>The results of this study therefore indicate that cortactin, through its interactions with Arp2/3 and filamentous actin, facilitates the resecretion and deposition of internalized, processed fibronectin to promote cell migration. However, given its high affinity for these partners, cortactin is almost certain to also regulate actin dynamics elsewhere in the cell \x{2014} for example, within lamellipodia.\xA0Although a primary role for cortactin in lamellipodia regulation was not important for cell motility in this study, Weaver\x{2019}s group considers that regulation of lamellipodial actin dynamics by cortactin might still contribute to efficient cell migration, perhaps under different circumstances.</p>

<p>Cortactin controls resecretion of exogenous fibronectin at the cell\x{2013}substrate interface, as revealed by live TIRF imaging of DyLight550-labelled fibronectin (FN). Control HT1080 fibrosarcoma cells (Sc; scrambled oligo) deposited fibronectin in linear streaks at the basal surface, thereby promoting cell migration, whereas cortactin-knockdown (KD) cells deposited markedly less fibronectin. Scale bar, 10 \x{3BC}m. Image courtesy of Dr Alissa M. Weaver, Vanderbilt University Medical Center, Nashville, TN, USA.</p>

