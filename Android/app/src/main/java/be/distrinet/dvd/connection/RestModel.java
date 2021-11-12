package be.distrinet.dvd.connection;

public class RestModel {
    public ContentObject[] records;

    public ContentObject[] getRecords() {
        return records;
    }

    public class ContentObject {
        String author;
        String title;
        String description;
        String image;

        public String getAuthor() {
            return author;
        }

        public String getTitle() {
            return title;
        }

        public String getDescription() {
            return description;
        }

        public String getImage() {
            return image;
        }





    }
}
