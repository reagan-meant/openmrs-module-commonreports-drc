package org.openmrs.module.drcreports.reports;

import java.io.File;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import org.dbunit.DatabaseUnitException;
import org.dbunit.DatabaseUnitRuntimeException;
import org.dbunit.database.DatabaseConfig;
import org.dbunit.database.DatabaseConnection;
import org.dbunit.database.IDatabaseConnection;
import org.dbunit.dataset.IDataSet;
import org.dbunit.ext.mysql.MySqlDataTypeFactory;
import org.dbunit.operation.DatabaseOperation;
import org.junit.Before;
import org.junit.Test;
import org.openmrs.Cohort;
import org.openmrs.api.ConceptService;
import org.openmrs.module.initializer.Domain;
import org.openmrs.module.initializer.api.InitializerService;
import org.openmrs.module.initializer.api.loaders.Loader;
import org.openmrs.module.reporting.common.DateUtil;
import org.openmrs.module.reporting.dataset.DataSetRow;
import org.openmrs.module.reporting.evaluation.EvaluationContext;
import org.openmrs.module.reporting.report.ReportData;
import org.openmrs.module.reporting.report.definition.ReportDefinition;
import org.openmrs.module.reporting.report.definition.service.ReportDefinitionService;
import org.openmrs.module.reporting.report.manager.ReportManagerUtil;
import org.openmrs.module.reporting.report.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import liquibase.Liquibase;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.jvm.JdbcConnection;
import liquibase.resource.ClassLoaderResourceAccessor;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;

public class DRCArtHepatitisReportManagerTest extends BaseModuleContextSensitiveMysqlBackedTest {
	
	public DRCArtHepatitisReportManagerTest() throws SQLException {
		super();
	}
	
	@Autowired
	@Qualifier("initializer.InitializerService")
	private InitializerService iniz;
	
	@Autowired
	private ReportService rs;
	
	@Autowired
	private ReportDefinitionService rds;
	
	@Autowired
	@Qualifier("conceptService")
	private ConceptService cs;
	
	@Autowired
	private DRCArtHepatitisReportManager manager;
	
	@Override
	public void executeDataSet(IDataSet dataset) {
		try {
			Connection connection = getConnection();
			IDatabaseConnection dbUnitConn = setupDatabaseConnection(connection);
			DatabaseOperation.REFRESH.execute(dbUnitConn, dataset);
		}
		catch (Exception e) {
			throw new DatabaseUnitRuntimeException(e);
		}
	}
	
	private IDatabaseConnection setupDatabaseConnection(Connection connection) throws DatabaseUnitException {
		IDatabaseConnection dbUnitConn = new DatabaseConnection(connection);
		
		DatabaseConfig config = dbUnitConn.getConfig();
		config.setProperty(DatabaseConfig.PROPERTY_DATATYPE_FACTORY, new MySqlDataTypeFactory());
		
		return dbUnitConn;
	}
	
	@Before
	public void setUp() throws Exception {
		updateDatabase("org/openmrs/module/drcreports/liquibase/test-liquibase.xml");
		executeDataSet("org/openmrs/module/reporting/include/ReportTestDataset-openmrs-2.0.xml");
		executeDataSet("org/openmrs/module/drcreports/include/DRCArtHepatitisReportTestDataset.xml");
		
		String path = getClass().getClassLoader().getResource("testAppDataDir").getPath() + File.separator;
		System.setProperty("OPENMRS_APPLICATION_DATA_DIRECTORY", path);
		
		for (Loader loader : iniz.getLoaders()) {
			if (loader.getDomainName().equals(Domain.JSON_KEY_VALUES.getName())) {
				loader.load();
			}
		}
	}
	
	@Test
	public void setupReport_shouldCreateExcelTemplateDesign() throws Exception {
		// setup
		
		// replay
		ReportManagerUtil.setupReport(manager);
		
		// verify
		assertThat(rs.getReportDesignByUuid("0a4b31cf-bc98-4378-b585-6169a1a30053"), is(notNullValue()));
		
	}
	
	@Test
	public void testReport() throws Exception {
		// setup
		EvaluationContext context = new EvaluationContext();
		context.addParameterValue("startDate", DateUtil.parseDate("2025-06-01", "yyyy-MM-dd"));
		context.addParameterValue("endDate", DateUtil.parseDate("2025-06-30", "yyyy-MM-dd"));
		
		// replay
		ReportDefinition rd = manager.constructReportDefinition();
		ReportData data = rds.evaluate(rd, context);
		
		// verify
		for (Iterator<DataSetRow> itr = data.getDataSets().get(rd.getName()).iterator(); itr.hasNext();) {
			DataSetRow row = itr.next();
			Map<String, Integer> columnValuePairs = getColumnValues();
			for (String column : columnValuePairs.keySet()) {
				assertThat(column, ((Cohort) row.getColumnValue(column)).getSize(), is(columnValuePairs.get(column)));
			}
		}
		
	}
	
	private Map<String, Integer> getColumnValues() {
		Map<String, Integer> map = new HashMap<String, Integer>();
		map.put("PLHIV starting ART who were screened for hepatitis B virus.Females", 1);
		map.put("PLHIV starting ART who were screened for hepatitis B virus.Males", 0);
		map.put("PLHIV starting ART who were screened for hepatitis B virus.All", 1);
		map.put("PLHIV starting ART who were screened for hepatitis B virus.< 15 years", 0);
		map.put("PLHIV starting ART who were screened for hepatitis B virus.> 15 years", 1);
		
		map.put("PLHIV starting ART who were screened for hepatitis B virus with positive results.Females", 1);
		map.put("PLHIV starting ART who were screened for hepatitis B virus with positive results.Males", 0);
		map.put("PLHIV starting ART who were screened for hepatitis B virus with positive results.All", 1);
		map.put("PLHIV starting ART who were screened for hepatitis B virus with positive results.< 15 years", 0);
		map.put("PLHIV starting ART who were screened for hepatitis B virus with positive results.> 15 years", 1);
		
		map.put("PLHIV starting ART who were screened for hepatitis C virus.Females", 1);
		map.put("PLHIV starting ART who were screened for hepatitis C virus.Males", 0);
		map.put("PLHIV starting ART who were screened for hepatitis C virus.All", 1);
		map.put("PLHIV starting ART who were screened for hepatitis C virus.< 15 years", 0);
		map.put("PLHIV starting ART who were screened for hepatitis C virus.> 15 years", 1);
		
		map.put("PLHIV starting ART who were screened for hepatitis C virus with positive results.Females", 1);
		map.put("PLHIV starting ART who were screened for hepatitis C virus with positive results.Males", 0);
		map.put("PLHIV starting ART who were screened for hepatitis C virus with positive results.All", 1);
		map.put("PLHIV starting ART who were screened for hepatitis C virus with positive results.< 15 years", 0);
		map.put("PLHIV starting ART who were screened for hepatitis C virus with positive results.> 15 years", 1);
		
		return map;
		
	}
	
	private void updateDatabase(String filename) throws Exception {
		Liquibase liquibase = getLiquibase(filename);
		liquibase.update("Modify column datatype to longblob on reporting_report_design_resource table");
		liquibase.getDatabase().getConnection().commit();
	}
	
	private Liquibase getLiquibase(String filename) throws Exception {
		Database liquibaseConnection = DatabaseFactory.getInstance()
		        .findCorrectDatabaseImplementation(new JdbcConnection(getConnection()));
		
		liquibaseConnection.setDatabaseChangeLogTableName("LIQUIBASECHANGELOG");
		liquibaseConnection.setDatabaseChangeLogLockTableName("LIQUIBASECHANGELOGLOCK");
		
		return new Liquibase(filename, new ClassLoaderResourceAccessor(getClass().getClassLoader()), liquibaseConnection);
	}
}
