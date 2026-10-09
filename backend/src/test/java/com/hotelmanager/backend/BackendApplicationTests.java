package com.hotelmanager.backend;
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.beans.factory.annotation.Autowired;
import com.hotelmanager.backend.repository.UsuarioRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.net.*;
import java.net.http.*;
import java.util.UUID;
import java.util.regex.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT,properties={
 "spring.datasource.url=jdbc:h2:mem:hotelmanager_test;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
 "spring.datasource.driver-class-name=org.h2.Driver","spring.datasource.username=sa",
 "spring.datasource.password=","spring.jpa.hibernate.ddl-auto=create-drop"})
class BackendApplicationTests {
 static final String TEST_PASSWORD=UUID.randomUUID().toString();
 @DynamicPropertySource static void secrets(DynamicPropertyRegistry r){r.add("ADMIN_PASSWORD",()->TEST_PASSWORD);}
 @LocalServerPort int port;
 @Autowired UsuarioRepository users;
 @Autowired PasswordEncoder encoder;
 HttpClient client;
 @BeforeEach void setup(){client=HttpClient.newBuilder().cookieHandler(new CookieManager(null,CookiePolicy.ACCEPT_ALL)).followRedirects(HttpClient.Redirect.NEVER).build();}
 HttpResponse<String> send(String path,String method,String body,String token) throws Exception{
  var b=HttpRequest.newBuilder(URI.create("http://localhost:"+port+path));
  if(token!=null)b.header("X-CSRF-TOKEN",token);
  if(body!=null)b.header("Content-Type",path.equals("/login")?"application/x-www-form-urlencoded":"application/json");
  return client.send(b.method(method,body==null?HttpRequest.BodyPublishers.noBody():HttpRequest.BodyPublishers.ofString(body)).build(),HttpResponse.BodyHandlers.ofString());
 }
 String field(String json,String key){var m=Pattern.compile("\""+key+"\":\"([^\"]+)\"").matcher(json);assertTrue(m.find(),json);return m.group(1);}
 String csrf() throws Exception {var r=send("/api/csrf","GET",null,null);assertEquals(200,r.statusCode());return field(r.body(),"token");}
 String login() throws Exception{
  var r=send("/login","POST","username=admin&password="+TEST_PASSWORD+"&_csrf="+URLEncoder.encode(csrf(),java.nio.charset.StandardCharsets.UTF_8),null);
  assertEquals(302,r.statusCode());return csrf();
 }
 @Test void anonymousAndCsrfProtection() throws Exception{
  assertEquals(401,send("/api/habitaciones","GET",null,null).statusCode());
  assertEquals(403,send("/api/habitaciones","POST","{}",null).statusCode());
  assertEquals(401,send("/api/habitaciones","POST","{}",csrf()).statusCode());
  assertEquals(302,send("/","GET",null,null).statusCode());
  assertEquals(200,send("/login.html","GET",null,null).statusCode());
 }
 @Test void loginLogoutAndBcrypt() throws Exception{
  var u=users.findByUsername("admin").orElseThrow();
  assertTrue(u.getPassword().startsWith("$2"));assertNotEquals(TEST_PASSWORD,u.getPassword());
  assertTrue(encoder.matches(TEST_PASSWORD,u.getPassword()));
  assertEquals(302,send("/login","POST","username=admin&password=incorrect&_csrf="+URLEncoder.encode(csrf(),java.nio.charset.StandardCharsets.UTF_8),null).statusCode());
  String token=login();
  assertEquals(200,send("/","GET",null,null).statusCode());
  assertEquals(403,send("/api/habitaciones","POST","{}",null).statusCode());
  assertEquals(403,send("/logout","POST",null,null).statusCode());
  assertEquals(302,send("/logout","POST",null,token).statusCode());
  assertEquals(401,send("/api/habitaciones","GET",null,null).statusCode());
 }
 @Test void crudValidationAndConflict() throws Exception{
  String token=login();
  String data="{\"numero\":9091,\"tipo\":\"Individual\",\"precio\":55.00,\"disponible\":true}";
  assertEquals(400,send("/api/habitaciones","POST","{\"numero\":-1,\"tipo\":\"\",\"precio\":-5}",token).statusCode());
  var created=send("/api/habitaciones","POST",data,token);assertEquals(201,created.statusCode());
  var match=Pattern.compile("\"id\":(\\d+)").matcher(created.body());assertTrue(match.find());String path="/api/habitaciones/"+match.group(1);
  try{
   assertEquals(200,send("/api/habitaciones","GET",null,null).statusCode());
   assertEquals(200,send(path,"GET",null,null).statusCode());
   assertEquals(409,send("/api/habitaciones","POST",data,token).statusCode());
   assertEquals(200,send(path,"PUT",data.replace("55.00","65.00"),token).statusCode());
   assertTrue(send(path,"GET",null,null).body().contains("65.00"));
  }finally{assertEquals(204,send(path,"DELETE",null,token).statusCode());}
  assertEquals(404,send(path,"GET",null,null).statusCode());
  assertEquals(404,send(path,"DELETE",null,token).statusCode());
 }
}
