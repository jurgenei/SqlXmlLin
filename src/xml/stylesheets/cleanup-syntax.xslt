<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://ing.com/vortex/sql/grammar" xmlns:g="http://ing.com/vortex/sql/grammar"
    xmlns:c="http://ing.com/vortex/sql/comments" xmlns:f="http://ing.com/vortex/sql/functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="f xs g">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
    <xsl:preserve-space elements="c:*"/>
    <xsl:template match="/">
        <envelope xmlns="http://ing.com/vortex/sql/grammar"
            xmlns:g="http://ing.com/vortex/sql/grammar" xmlns:c="http://ing.com/vortex/sql/comments">
            <xsl:variable name="a" as="node()*">
                <xsl:apply-templates mode="join-tokens"/>
            </xsl:variable>
            <xsl:variable name="b" as="node()*">
                <xsl:apply-templates mode="join-comments" select="$a"/>
            </xsl:variable>
            <xsl:variable name="c" as="node()*">
                <xsl:apply-templates mode="simplify-grammar" select="$b"/>
            </xsl:variable>
            <xsl:variable name="d" as="node()*">
                <xsl:apply-templates mode="shuffle-comments" select="$c"/>
            </xsl:variable>
            <xsl:variable name="e" as="node()*">
                <xsl:apply-templates mode="assign-ids" select="$d"/>
            </xsl:variable>
            <xsl:apply-templates mode="rewrite-alias" select="$e"/>
        </envelope>
    </xsl:template>
    <!--
        Concat Tokens, specially || expressions
      -->
    <xsl:template match="*[g:t]" mode="join-tokens">
        <xsl:variable name="children" select="*"/>
        <xsl:element name="{name(.)}">
            <xsl:sequence select="f:bundle-tokens($children, ())"/>
        </xsl:element>
    </xsl:template>
    <!--
        Join comments
      -->
    <xsl:template match="*[c:*]" mode="join-comments">
        <xsl:variable name="children" select="*" as="node()*"/>
        <xsl:element name="{name(.)}">
            <xsl:sequence select="f:bundle-comments($children, ())"/>
        </xsl:element>
    </xsl:template>
    <!--
        Push last c of sequence until after element
    -->
    <xsl:template match="*[c:*]" mode="shuffle-comments">
        <xsl:variable name="children" select="*" as="node()*"/>
        <xsl:variable name="last" select="$children[position() = last()]" as="node()*"/>
        <xsl:choose>
            <xsl:when test="namespace-uri($last) = 'http://ing.com/vortex/sql/comments'">
                <xsl:element name="{name(.)}">
                    <xsl:apply-templates select="$children[position() != last()]" mode="#current"/>
                </xsl:element>
                <xsl:sequence select="$last"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{name(.)}">
                    <xsl:apply-templates select="$children" mode="#current"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        Simplify Grammar pass
      -->
    <xsl:template
        match="g:table-alias | g:tableview-name | g:identifier | g:id-expression | g:regular-id"
        mode="simplify-grammar" priority="10">
        <xsl:variable name="tok" select=".//g:t" as="node()*"/>
        <id>
            <xsl:value-of select="$tok"/>
        </id>
        <xsl:if test="$tok/following-sibling::c:*">
            <xsl:copy-of select="$tok/following-sibling::c:*"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="g:quoted-string | g:numeric | g:constant" mode="simplify-grammar"
        priority="10">
        <xsl:variable name="tok" select=".//g:t" as="node()*"/>
        <const>
            <xsl:value-of select="$tok"/>
        </const>
        <xsl:if test="$tok/following-sibling::c:*">
            <xsl:copy-of select="$tok/following-sibling::c:*"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="g:relational-operator" mode="simplify-grammar" priority="10">
        <xsl:variable name="tok" select=".//g:t" as="node()*"/>
        <relop>
            <xsl:value-of select="$tok"/>
        </relop>
        <xsl:if test="$tok/following-sibling::c:*">
            <xsl:copy-of select="$tok/following-sibling::c:*"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="g:outer-join-sign" mode="simplify-grammar" priority="10">
        <xsl:variable name="tok" select=".//g:t" as="node()*"/>
        <outer-join>
            <xsl:value-of select="string-join($tok/text(), '')"/>
        </outer-join>
        <xsl:if test="$tok/following-sibling::c:*">
            <xsl:copy-of select="$tok/following-sibling::c:*"/>
        </xsl:if>
    </xsl:template>

    <!--  labelling of ids  -->


    <xsl:template match="g:general-table-ref/g:id" mode="assign-ids">
        <table>
            <xsl:value-of select="."/>
        </table>
    </xsl:template>
    <xsl:template match="g:dml-table-expression-clause/g:id" mode="assign-ids">
        <table>
            <xsl:value-of select="."/>
        </table>
    </xsl:template>
    <xsl:template match="g:table-ref-aux-internal/g:id" mode="assign-ids">
        <table>
            <xsl:value-of select="."/>
        </table>
    </xsl:template>
    <xsl:template match="g:table-ref-aux/g:id" mode="assign-ids">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>
    <xsl:template match="g:select-list-elements/g:id" mode="assign-ids">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>
    <xsl:template match="g:general-element-part/g:id[position() = 1]" mode="assign-ids">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>
    <xsl:template match="g:expression/g:id" mode="assign-ids">
        <column>
            <xsl:value-of select="."/>
        </column>
    </xsl:template>
    <xsl:template match="g:general-element-part/g:id[position() = 2]" mode="assign-ids">
        <column>
            <xsl:value-of select="."/>
        </column>
    </xsl:template>
    <xsl:template match="g:column-alias" mode="assign-ids">
        <column-alias>
            <xsl:value-of select="g:id"/>
        </column-alias>
    </xsl:template>
    <xsl:template match="g:merge-target/g:id[position() = 1]" mode="assign-ids">
        <table>
            <xsl:value-of select="."/>
        </table>
    </xsl:template>
    <xsl:template match="g:merge-target/g:id[position() = 2]" mode="assign-ids">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>


    <xsl:template match="g:t[not(ancestor::g:regular-id)]" mode="simplify-grammar">
        <t>
            <xsl:value-of select="."/>
        </t>
    </xsl:template>

    <!--  remove elements with one g: child -->
    <xsl:template
        match="g:*[count(g:*) = 1 and count(node()) = 1][matches(local-name(), '-expression|concatenation|atom|standard-function|general-element')]"
        mode="simplify-grammar">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <!--  re-shuffle alias underneath select-list-elements into first expression where it belongs -->
    <xsl:template match="g:select-list-elements" mode="rewrite-alias">
        <select-list-elements>
            <xsl:apply-templates select="g:expressions" mode="#current"/>
        </select-list-elements>
    </xsl:template>
    <xsl:template match="g:select-list-elements/g:expressions/g:expression[position() = 1]"
        mode="rewrite-alias" priority="1">
        <expression>
            <xsl:copy-of select="../../(* except g:expressions)"/>
            <xsl:apply-templates mode="#current"/>
        </expression>
    </xsl:template>
    <xsl:template
        match="g:select-list-elements/g:expressions/g:expression[position() gt 1][g:general-element-part and c:c]"
        mode="rewrite-alias" priority="1">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="g:select-list-elements/g:expressions" mode="rewrite-alias">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="g:query-block/g:selected-element" mode="rewrite-alias">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="g:table-ref-aux | g:table-ref-aux-internal" mode="rewrite-alias">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="g:table-ref" mode="rewrite-alias">
        <table-ref>
            <xsl:apply-templates select="* except c:c[position() = last()]" mode="rewrite-alias"/>
        </table-ref>
        <xsl:apply-templates select="c:c[position() = last()]" mode="rewrite-alias"/>
    </xsl:template>

    <xsl:template match="g:subquery | g:subquery-basic-elements | g:query-block"
        mode="rewrite-alias">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!--
        rewrites
      -->
    <xsl:template match="g:merge-target/g:table" mode="rewrite-alias">
        <table>
            <xsl:value-of select="."/>
        </table>
    </xsl:template>
    <xsl:template match="g:selected-tableview/g:id[not(position() = last())]" mode="rewrite-alias" priority="1">
        <table>
            <xsl:value-of select="."/>
        </table>
    </xsl:template>
    <xsl:template match="g:selected-tableview/g:id[position() = last()]" mode="rewrite-alias" priority="1">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>
    <xsl:template match="g:merge-target/g:table-alias" mode="rewrite-alias">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>
    <xsl:template match="g:column-name[count(g:id) gt 1]/g:id[position() = 1]" mode="rewrite-alias"
        priority="1">
        <table-alias>
            <xsl:value-of select="."/>
        </table-alias>
    </xsl:template>
    <xsl:template match="g:column-name/g:id[position() = last()]" mode="rewrite-alias" priority="1">
        <column>
            <xsl:value-of select="."/>
        </column>
    </xsl:template>
    <xsl:template match="g:id[ancestor::g:expression]" mode="rewrite-alias" priority="1">
        <column>
            <xsl:value-of select="."/>
        </column>
    </xsl:template>
    
    <xsl:template match="g:relational-expression" mode="rewrite-alias">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="g:general-element-part" mode="rewrite-alias">
        <expression>
            <xsl:apply-templates mode="#current"/>
        </expression>
    </xsl:template>

    <!--
        Default Copy Rule
      -->
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Functions
      -->
    <xsl:function name="f:bundle-comments" as="node()*">
        <xsl:param name="children" as="node()*"/>
        <xsl:param name="comments" as="node()*"/>
        <xsl:variable name="first" select="$children[1]"/>
        <xsl:variable name="rest" select="$children[position() gt 1]"/>
        <xsl:choose>
            <xsl:when test="empty($children)">
                <xsl:sequence select="f:lay-comments($comments)"/>
            </xsl:when>
            <xsl:when test="namespace-uri($first) eq 'http://ing.com/vortex/sql/comments'">
                <xsl:sequence select="f:bundle-comments($rest, ($comments, $first))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="f:lay-comments($comments)"/>
                <xsl:apply-templates select="$first" mode="join-comments"/>
                <xsl:sequence select="f:bundle-comments($rest, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="f:lay-comments">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:if test="not(empty($nodes))">
            <c:c>
                <xsl:value-of select="string-join($nodes/text(), '')"/>
            </c:c>
        </xsl:if>
    </xsl:function>
    <xsl:function name="f:bundle-tokens" as="node()*">
        <xsl:param name="children" as="node()*"/>
        <xsl:param name="tokens" as="node()*"/>
        <xsl:variable name="first" select="$children[1]"/>
        <xsl:variable name="rest" select="$children[position() gt 1]"/>
        <xsl:choose>
            <xsl:when test="empty($children)">
                <xsl:sequence select="f:lay-tokens($tokens)"/>
            </xsl:when>
            <xsl:when test="$first/self::g:t">
                <xsl:sequence select="f:bundle-tokens($rest, ($tokens, $first))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="f:lay-tokens($tokens)"/>
                <xsl:apply-templates select="$first" mode="join-tokens"/>
                <xsl:sequence select="f:bundle-tokens($rest, ())"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="f:lay-tokens">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:if test="not(empty($nodes))">
            <t>
                <xsl:value-of select="string-join($nodes/text(), '')"/>
            </t>
        </xsl:if>
    </xsl:function>
</xsl:stylesheet>
