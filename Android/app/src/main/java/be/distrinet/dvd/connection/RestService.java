package be.distrinet.dvd.connection;

import io.reactivex.Single;
import retrofit2.http.GET;

public interface RestService {

    @GET("/")
    Single<RestModel> getData();


}
